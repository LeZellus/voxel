# scripts/systems/inventory/actions/HandPlacementAction.gd
class_name HandPlacementAction
extends BaseInventoryAction

func _init():
	super("hand_placement", 9)  # Entre RestackAction (8) et SimpleMoveAction (10)

func can_execute(context: ClickContext) -> bool:
	"""
	Active quand :
	- Clic gauche
	- Le joueur a quelque chose en main
	- Le slot source vient de la "main" (slot_index = -1)
	"""
	return (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK 
			and context.source_slot_index == -1
			and context.target_slot_index != -1
			and player_has_selection())

func execute(context: ClickContext) -> bool:
	"""Gère le placement depuis la main vers un slot"""
	print("🔄 [ACTION] Placement depuis la main vers slot %d" % context.target_slot_index)
	
	# Récupérer les données de l'item en main
	var hand_data = get_hand_data()
	var hand_item_id = hand_data.get("item_id", "")
	var hand_quantity = hand_data.get("quantity", 0)
	
	if hand_item_id == "" or hand_quantity <= 0:
		print("❌ Données d'item en main invalides")
		return false
	
	# Récupérer le controller du container cible
	var target_controller = get_controller(context.target_container_id)
	if not target_controller:
		print("❌ Controller cible introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
	if not target_slot:
		print("❌ Slot cible introuvable")
		return false
	
	# Créer un item temporaire pour le transfert
	var temp_item = create_item_from_data(hand_data)
	if not temp_item:
		print("❌ Impossible de créer l'item temporaire")
		return false
	
	print("📦 Placement: %s x%d vers slot %d" % [temp_item.name, hand_quantity, context.target_slot_index])
	
	# Effectuer le transfert
	var success = _transfer_hand_item_to_slot(target_slot, temp_item, hand_quantity)
	
	if success:
		# Rafraîchir l'UI
		call_deferred("refresh_container_ui", context.target_container_id)
	
	return success

func _transfer_hand_item_to_slot(target_slot, item: Item, quantity: int) -> bool:
	"""Transfère l'item de la main vers le slot cible"""
	
	# CAS 1: Slot vide - placement direct
	if target_slot.is_empty():
		print("📥 Slot vide - placement direct")
		var surplus = target_slot.add_item(item, quantity)
		
		if surplus == 0:
			# Tout placé - vider la main
			clear_hand_selection()
			print("✅ Placement complet")
			return true
		else:
			# Partiellement placé - mettre à jour la main
			update_hand_quantity(surplus)
			print("⚠️ Placement partiel: %d restants en main" % surplus)
			return true
	
	# CAS 2: Même item - tentative de stack
	elif target_slot.get_item().id == item.id and item.is_stackable:
		print("📚 Tentative de stack...")
		
		var available_space = target_slot.get_max_stack_size() - target_slot.get_quantity()
		var can_stack = min(quantity, available_space)
		
		if can_stack > 0:
			# Ajouter au stack existant
			target_slot.item_stack.quantity += can_stack
			target_slot.slot_changed.emit()
			
			var remaining = quantity - can_stack
			if remaining > 0:
				# Mettre à jour la quantité en main
				update_hand_quantity(remaining)
				print("✅ Stack partiel: %d ajoutés, %d restants en main" % [can_stack, remaining])
			else:
				# Tout stacké - vider la main
				clear_hand_selection()
				print("✅ Stack complet")
			
			return true
		else:
			print("❌ Stack impossible - slot plein")
			return false
	
	# CAS 3: Items différents - swap
	else:
		print("🔄 Swap avec item différent")
		
		# Récupérer l'item du slot
		var slot_item = target_slot.get_item()
		var slot_quantity = target_slot.get_quantity()
		
		# Vider le slot
		target_slot.clear()
		
		# Placer l'item de la main
		var surplus = target_slot.add_item(item, quantity)
		
		# Mettre l'ancien item de la main
		if surplus == 0:
			activate_hand_selection(slot_item, slot_quantity)
			print("✅ Swap réussi: %s <-> %s" % [item.name, slot_item.name])
		else:
			# Cas complexe - restaurer et échouer
			target_slot.clear()
			target_slot.add_item(slot_item, slot_quantity)
			print("⚠️ Swap impossible - gestion complexe non supportée")
			return false
		
		return true
