# scripts/systems/inventory/actions/HandPlacementAction.gd - VERSION CORRIGÉE
class_name HandPlacementAction
extends BaseInventoryAction

func _init():
	super("hand_placement", 3)  # Priorité après RestackAction

func can_execute(context: ClickContext) -> bool:
	var has_selection = player_has_selection()
	var is_left_click = (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK)
	var has_target = (context.target_slot_index == -1)  # Pas de contexte slot-to-slot
	
	return has_selection and is_left_click and has_target

func execute(context: ClickContext) -> bool:
	print("\n🚀 === HANDPLACEMENTACTION.EXECUTE ===")
	
	var integrator = get_integrator()
	if not integrator:
		print("❌ Integrator introuvable")
		return false
	
	var hand_data = integrator.selected_slot_info.slot_data
	var hand_slot_index = integrator.selected_slot_info.get("slot_index", -1)
	var hand_container_id = integrator.selected_slot_info.get("container_id", "")
	
	# Vérifier si c'est un dépôt au même endroit
	if (hand_slot_index == context.source_slot_index and 
		hand_container_id == context.source_container_id):
		print("🚫 Même slot - annulation sélection")
		clear_hand_selection()
		return true
	
	# Récupérer les controllers
	var target_controller = get_controller(context.source_container_id)
	var source_controller = get_controller(hand_container_id) if hand_slot_index != -1 else null
	
	if not target_controller:
		print("❌ Controller target introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot:
		print("❌ Slot target introuvable")
		return false
	
	# NOUVEAU : Récupérer le slot source réel si pas en main pure
	var source_slot = null
	if source_controller and hand_slot_index != -1:
		source_slot = source_controller.inventory.get_slot(hand_slot_index)
	
	var hand_item = create_item_from_data(hand_data)
	var hand_quantity = hand_data.get("quantity", 0)
	
	print("   - Main: %s x%d → slot %d" % [hand_item.name, hand_quantity, context.source_slot_index])
	
	var success = false
	
	if target_slot.is_empty():
		success = _execute_direct_placement(target_slot, source_slot, hand_item, hand_quantity)
	elif target_slot.get_item().id == hand_item.id and hand_item.is_stackable:
		success = _execute_stack_placement(target_slot, source_slot, hand_item, hand_quantity)
	else:
		success = _execute_swap_placement(target_slot, source_slot, hand_item, hand_quantity)
	
	if success:
		clear_hand_selection()
		_force_refresh_after_placement(context, hand_container_id)
	
	return success

func _execute_direct_placement(target_slot, source_slot, item: Item, quantity: int) -> bool:
	"""Placement direct avec retrait du slot source"""
	var surplus = target_slot.add_item(item, quantity)
	
	if surplus < quantity:  # Quelque chose a été placé
		var placed_amount = quantity - surplus
		
		# CORRECTION : Retirer du slot source si existe
		if source_slot:
			var removed = source_slot.remove_item(placed_amount)
			if removed.quantity != placed_amount:
				print("⚠️ Quantité retirée incohérente: %d vs %d" % [removed.quantity, placed_amount])
		
		print("✅ Placement réussi: %d items" % placed_amount)
		
		# S'il reste des items, les remettre en sélection
		if surplus > 0:
			activate_hand_selection(item, surplus)
			return false  # Placement partiel
	
	return surplus == 0

func _execute_stack_placement(target_slot, source_slot, item: Item, quantity: int) -> bool:
	"""Stack avec retrait du slot source"""
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	if available_space <= 0:
		print("❌ Slot target déjà plein")
		return false
	
	var can_stack = min(quantity, available_space)
	
	# CORRECTION : Modifier atomiquement
	target_slot.item_stack.quantity += can_stack
	
	# CORRECTION : Retirer du slot source si existe
	if source_slot:
		var removed = source_slot.remove_item(can_stack)
		if removed.quantity != can_stack:
			print("⚠️ Erreur dans le retrait du slot source")
			# Rollback
			target_slot.item_stack.quantity -= can_stack
			return false
	
	var remaining = quantity - can_stack
	
	if remaining > 0:
		activate_hand_selection(item, remaining)
		print("✅ Stack partiel: %d ajoutés, %d restants" % [can_stack, remaining])
		return false  # Retour false pour garder la sélection
	else:
		print("✅ Stack complet: %d ajoutés" % can_stack)
		return true

func _execute_swap_placement(target_slot, source_slot, item: Item, quantity: int) -> bool:
	"""Swap avec gestion du slot source"""
	var slot_item = target_slot.get_item()
	var slot_quantity = target_slot.get_quantity()
	
	# Effectuer le swap
	target_slot.clear()
	target_slot.add_item(item, quantity)
	
	# CORRECTION : Gérer le slot source
	if source_slot:
		source_slot.clear()
		source_slot.add_item(slot_item, slot_quantity)
	else:
		# Mettre l'ancien item en main
		activate_hand_selection(slot_item, slot_quantity)
		return false  # Garder la sélection active
	
	print("✅ Swap réussi: %s ↔ %s" % [item.name, slot_item.name])
	return true

func _force_refresh_after_placement(context: ClickContext, source_container_id: String = ""):
	"""Force le refresh après placement"""
	# Refresh du container target
	call_deferred("refresh_container_ui", context.source_container_id)
	
	# Refresh du container source si différent
	if source_container_id != "" and source_container_id != context.source_container_id:
		call_deferred("refresh_container_ui", source_container_id)
