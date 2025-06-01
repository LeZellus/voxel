# scripts/systems/inventory/actions/HandPlacementAction.gd - VERSION SIMPLIFIÉE
class_name HandPlacementAction
extends BaseInventoryAction

func _init():
	super("hand_placement", 2)

func can_execute(context: ClickContext) -> bool:
	# Seulement si on a quelque chose en main et clic gauche
	var has_selection = player_has_selection()
	var is_left_click = (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK)
	var no_target = (context.target_slot_index == -1)
	
	return has_selection and is_left_click and no_target

func execute(context: ClickContext) -> bool:
	print("\n🚀 [HAND-PLACEMENT] Placement en cours...")
	
	var integrator = get_integrator()
	if not integrator:
		print("❌ Integrator introuvable")
		return false
	
	var hand_data = integrator.selected_slot_info.slot_data
	var hand_slot_index = integrator.selected_slot_info.get("slot_index", -1)
	var hand_container_id = integrator.selected_slot_info.get("container_id", "")
	
	# Vérifier si c'est le même slot (annulation)
	if (hand_slot_index == context.source_slot_index and 
		hand_container_id == context.source_container_id):
		print("🚫 Même slot - annulation sélection")
		clear_hand_selection()
		return true
	
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		print("❌ Controller target introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot:
		print("❌ Slot target introuvable")
		return false
	
	var hand_item = create_item_from_data(hand_data)
	var hand_quantity = hand_data.get("quantity", 0)
	
	print("   📦 Placement: %s x%d -> slot %d" % [hand_item.name, hand_quantity, context.source_slot_index])
	
	var success = false
	
	if target_slot.is_empty():
		# Slot vide : placement direct
		success = _place_in_empty_slot(target_slot, hand_item, hand_quantity, hand_slot_index, hand_container_id)
	elif target_slot.get_item().id == hand_item.id and hand_item.is_stackable:
		# Même item : tentative de stack
		success = _stack_with_existing(target_slot, hand_item, hand_quantity, hand_slot_index, hand_container_id)
	else:
		# Items différents : swap
		success = _swap_items(target_slot, hand_item, hand_quantity, hand_slot_index, hand_container_id)
	
	if success:
		clear_hand_selection()
	
	# Forcer refresh
	call_deferred("refresh_container_ui", context.source_container_id)
	if hand_container_id != context.source_container_id:
		call_deferred("refresh_container_ui", hand_container_id)
	
	return success

func _place_in_empty_slot(target_slot, item: Item, quantity: int, source_slot_index: int, source_container_id: String) -> bool:
	"""Placement dans un slot vide"""
	print("   ✅ Placement direct dans slot vide")
	
	# Ajouter au slot target
	var surplus = target_slot.add_item(item, quantity)
	
	# Vider le slot source si ce n'est pas une main pure
	if source_slot_index != -1:
		var source_controller = get_controller(source_container_id)
		if source_controller:
			var source_slot = source_controller.inventory.get_slot(source_slot_index)
			if source_slot:
				source_slot.clear()
	
	# S'il y a un surplus, le remettre en main
	if surplus > 0:
		activate_hand_selection(item, surplus)
		return false  # Placement partiel
	
	return true

func _stack_with_existing(target_slot, item: Item, quantity: int, source_slot_index: int, source_container_id: String) -> bool:
	"""Stack avec un item existant"""
	var available_space = target_slot.get_max_stack_size() - target_slot.get_quantity()
	
	if available_space <= 0:
		print("   ❌ Slot target déjà plein")
		return false
	
	var can_stack = min(quantity, available_space)
	var remaining = quantity - can_stack
	
	print("   📚 Stack: +%d, reste %d" % [can_stack, remaining])
	
	# Ajouter au target
	target_slot.item_stack.quantity += can_stack
	
	# Vider ou réduire le slot source
	if source_slot_index != -1:
		var source_controller = get_controller(source_container_id)
		if source_controller:
			var source_slot = source_controller.inventory.get_slot(source_slot_index)
			if source_slot:
				if remaining > 0:
					source_slot.item_stack.quantity = remaining
				else:
					source_slot.clear()
	
	# Remettre le reste en main si nécessaire
	if remaining > 0:
		activate_hand_selection(item, remaining)
		return false  # Stack partiel
	
	# Émettre les signaux
	target_slot.slot_changed.emit()
	
	return true

func _swap_items(target_slot, hand_item: Item, hand_quantity: int, source_slot_index: int, source_container_id: String) -> bool:
	"""Échange d'items différents"""
	var slot_item = target_slot.get_item()
	var slot_quantity = target_slot.get_quantity()
	
	print("   🔄 Swap: %s ↔ %s" % [hand_item.name, slot_item.name])
	
	# Vider le target et y mettre l'item de la main
	target_slot.clear()
	target_slot.add_item(hand_item, hand_quantity)
	
	# Gérer le slot source
	if source_slot_index != -1:
		var source_controller = get_controller(source_container_id)
		if source_controller:
			var source_slot = source_controller.inventory.get_slot(source_slot_index)
			if source_slot:
				source_slot.clear()
				source_slot.add_item(slot_item, slot_quantity)
	else:
		# Mettre l'ancien item en main
		activate_hand_selection(slot_item, slot_quantity)
		return false  # Garder la sélection active
	
	# Émettre les signaux
	target_slot.slot_changed.emit()
	
	return true
