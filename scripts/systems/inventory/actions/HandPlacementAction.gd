# scripts/systems/inventory/actions/HandPlacementAction.gd - VERSION CORRIGÉE
class_name HandPlacementAction
extends BaseInventoryAction

func _init():
	super("hand_placement", 2)  # PRIORITÉ 2 - Après RestackAction

func can_execute(context: ClickContext) -> bool:
	"""
	CLARIFIÉ: Gère UNIQUEMENT main → slot
	- Le joueur a quelque chose en main
	- Clic gauche sur n'importe quel slot (vide ou non)
	"""
	print("\n🔍 === HANDPLACEMENTACTION.CAN_EXECUTE ===")
	
	var has_selection = player_has_selection()
	var is_left_click = (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK)
	var has_target = (context.target_slot_index == -1)  # Pas de contexte slot-to-slot
	
	var result = has_selection and is_left_click and has_target
	
	if result:
		var hand_data = get_hand_data()
		print("✅ HandPlacement peut exécuter: %s x%d → slot %d" % [
			hand_data.get("item_name", "?"),
			hand_data.get("quantity", 0),
			context.source_slot_index
		])
	else:
		print("❌ HandPlacement ne peut pas exécuter")
		print("     - A sélection: %s" % has_selection)
		print("     - Clic gauche: %s" % is_left_click)
		print("     - Pas de target: %s" % has_target)
	
	return result

func execute(context: ClickContext) -> bool:
	"""Gère le placement depuis la main - VERSION SIMPLIFIÉE"""
	print("\n🚀 === HANDPLACEMENTACTION.EXECUTE ===")
	
	var hand_data = get_hand_data()
	var hand_item_id = hand_data.get("item_id", "")
	var hand_quantity = hand_data.get("quantity", 0)
	var hand_item_type = hand_data.get("item_type", -1)
	
	print("   - Main: %s x%d → slot %d" % [
		hand_data.get("item_name", "?"), hand_quantity, context.source_slot_index
	])
	
	# Récupérer le slot cible
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		print("❌ Controller target introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot:
		print("❌ Slot target introuvable")
		return false
	
	# DÉTERMINER LE TYPE D'OPÉRATION
	if target_slot.is_empty():
		print("📥 Slot vide - placement direct")
		return _execute_direct_placement(target_slot, hand_data, context)
	
	elif target_slot.get_item().id == hand_item_id and hand_item_type != Item.ItemType.TOOL:
		print("📚 Même item - tentative de stack")
		return _execute_stack_placement(target_slot, hand_data, context)
	
	else:
		print("🔄 Items différents - swap")
		return _execute_swap_placement(target_slot, hand_data, context)

func _execute_direct_placement(target_slot, hand_data: Dictionary, context: ClickContext) -> bool:
	"""Placement dans un slot vide"""
	var hand_item = create_item_from_data(hand_data)
	var hand_quantity = hand_data.get("quantity", 0)
	
	# Placement direct
	var surplus = target_slot.add_item(hand_item, hand_quantity)
	
	if surplus == 0:
		# Tout placé
		clear_hand_selection()
		print("✅ Placement complet")
	else:
		# Placement partiel
		update_hand_quantity(surplus)
		print("⚠️ Placement partiel: %d restants en main" % surplus)
	
	_force_refresh_after_placement(context)
	return true

func _execute_stack_placement(target_slot, hand_data: Dictionary, context: ClickContext) -> bool:
	"""Stack avec un item identique"""
	var hand_quantity = hand_data.get("quantity", 0)
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	print("📊 Stack: main %d + slot %d/%d (espace: %d)" % [
		hand_quantity, target_current, target_max, available_space
	])
	
	if available_space <= 0:
		print("❌ Slot target déjà plein")
		return false
	
	var can_stack = min(hand_quantity, available_space)
	var remaining_in_hand = hand_quantity - can_stack
	
	# Effectuer le stack
	target_slot.item_stack.quantity += can_stack
	
	if remaining_in_hand > 0:
		update_hand_quantity(remaining_in_hand)
		print("✅ Stack partiel: %d ajoutés, %d restants en main" % [can_stack, remaining_in_hand])
	else:
		clear_hand_selection()
		print("✅ Stack complet: %d ajoutés" % can_stack)
	
	_force_refresh_after_placement(context)
	return true

func _execute_swap_placement(target_slot, hand_data: Dictionary, context: ClickContext) -> bool:
	"""Échange avec un item différent"""
	var hand_item = create_item_from_data(hand_data)
	var hand_quantity = hand_data.get("quantity", 0)
	
	# Sauvegarder l'item du slot
	var slot_item = target_slot.get_item()
	var slot_quantity = target_slot.get_quantity()
	
	# Effectuer le swap atomique
	target_slot.clear()
	target_slot.add_item(hand_item, hand_quantity)
	
	# Mettre l'ancien item du slot en main
	activate_hand_selection(slot_item, slot_quantity)
	
	print("✅ Swap réussi: %s ↔ %s" % [hand_item.name, slot_item.name])
	
	_force_refresh_after_placement(context)
	return true

func _force_refresh_after_placement(context: ClickContext):
	"""Force le refresh après placement"""
	# Émettre les signaux
	var target_controller = get_controller(context.source_container_id)
	if target_controller:
		var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
		if target_slot:
			target_slot.slot_changed.emit()
		target_controller.inventory.inventory_changed.emit()
	
	# Refresh UI
	call_deferred("refresh_container_ui", context.source_container_id)
