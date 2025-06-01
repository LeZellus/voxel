# scripts/systems/inventory/actions/RestackAction.gd
class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 8)  # Priorité PLUS HAUTE que SimpleMoveAction (10)

func can_execute(context: ClickContext) -> bool:
	"""
	Active pour regrouper des stacks identiques dans TOUS les cas
	"""
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		return false
	
	# CAS 1: Item en main → slot cliqué
	if player_has_selection():
		return _can_execute_hand_to_slot(context)
	
	# CAS 2: Slot sélectionné → slot cliqué (avec target_slot_index != -1)
	if context.target_slot_index != -1:
		return _can_execute_slot_to_slot(context)
	
	return false

func _can_execute_hand_to_slot(context: ClickContext) -> bool:
	"""Vérifie si on peut faire un restack main → slot"""
	var clicked_slot_index = context.source_slot_index
	var clicked_slot_data = context.source_slot_data
	
	if clicked_slot_index == -1 or clicked_slot_data.get("is_empty", true):
		return false
	
	var hand_data = get_hand_data()
	var hand_item_id = hand_data.get("item_id", "")
	var clicked_item_id = clicked_slot_data.get("item_id", "")
	
	if hand_item_id != clicked_item_id or hand_item_id == "":
		return false
	
	var hand_item_type = hand_data.get("item_type", -1)
	if hand_item_type == Item.ItemType.TOOL:
		return false
	
	print("🔍 RestackAction: ✅ Main → Slot possible pour %s" % hand_item_id)
	return true

func _can_execute_slot_to_slot(context: ClickContext) -> bool:
	"""Vérifie si on peut faire un restack slot → slot"""
	var source_slot_data = context.source_slot_data
	var target_slot_data = context.target_slot_data
	
	# Les deux slots doivent avoir des items
	if source_slot_data.get("is_empty", true) or target_slot_data.get("is_empty", true):
		return false
	
	var source_item_id = source_slot_data.get("item_id", "")
	var target_item_id = target_slot_data.get("item_id", "")
	
	# Même item seulement
	if source_item_id != target_item_id or source_item_id == "":
		return false
	
	var source_item_type = source_slot_data.get("item_type", -1)
	if source_item_type == Item.ItemType.TOOL:
		return false
	
	print("🔍 RestackAction: ✅ Slot → Slot possible pour %s" % source_item_id)
	return true

func execute(context: ClickContext) -> bool:
	"""Exécute le restack selon le cas"""
	if player_has_selection():
		return _execute_hand_to_slot(context)
	else:
		return _execute_slot_to_slot(context)

func _execute_hand_to_slot(context: ClickContext) -> bool:
	"""Restack depuis la main vers le slot cliqué"""
	print("🔄 [ACTION] Restack Main → Slot %d" % context.source_slot_index)
	
	var hand_data = get_hand_data()
	var hand_quantity = hand_data.get("quantity", 0)
	var hand_item_id = hand_data.get("item_id", "")
	
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot or target_slot.is_empty():
		return false
	
	if target_slot.get_item().id != hand_item_id:
		return false
	
	# Calculer et effectuer le transfert
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	if available_space <= 0:
		print("❌ Slot cible déjà plein")
		return false
	
	var can_transfer = min(hand_quantity, available_space)
	var remaining_in_hand = hand_quantity - can_transfer
	
	target_slot.item_stack.quantity += can_transfer
	target_slot.slot_changed.emit()
	
	print("✅ Restack Main→Slot: %d transférés, %d restants" % [can_transfer, remaining_in_hand])
	
	if remaining_in_hand > 0:
		update_hand_quantity(remaining_in_hand)
	else:
		clear_hand_selection()
	
	call_deferred("refresh_container_ui", context.source_container_id)
	return true

func _execute_slot_to_slot(context: ClickContext) -> bool:
	"""Restack entre deux slots (optimisé par rapport à SimpleMoveAction)"""
	print("🔄 [ACTION] Restack Slot %d → Slot %d" % [context.source_slot_index, context.target_slot_index])
	
	var source_controller = get_controller(context.source_container_id)
	var target_controller = get_controller(context.target_container_id)
	
	if not source_controller or not target_controller:
		return false
	
	var source_slot = source_controller.inventory.get_slot(context.source_slot_index)
	var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		return false
	
	if source_slot.is_empty() or target_slot.is_empty():
		return false
	
	if source_slot.get_item().id != target_slot.get_item().id:
		return false
	
	# Calculer et effectuer le transfert
	var source_quantity = source_slot.get_quantity()
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	if available_space <= 0:
		print("❌ Slot cible déjà plein")
		return false
	
	var can_transfer = min(source_quantity, available_space)
	var remaining_in_source = source_quantity - can_transfer
	
	target_slot.item_stack.quantity += can_transfer
	target_slot.slot_changed.emit()
	
	if remaining_in_source > 0:
		source_slot.item_stack.quantity = remaining_in_source
		source_slot.slot_changed.emit()
	else:
		source_slot.clear()
	
	print("✅ Restack Slot→Slot: %d transférés, %d restants en source" % [can_transfer, remaining_in_source])
	
	call_deferred("refresh_container_ui", context.source_container_id)
	if context.source_container_id != context.target_container_id:
		call_deferred("refresh_container_ui", context.target_container_id)
	
	return true
