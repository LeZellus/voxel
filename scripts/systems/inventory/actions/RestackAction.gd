# scripts/systems/inventory/actions/RestackAction.gd - VERSION COMPLÈTEMENT CORRIGÉE
class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 1) # PRIORITÉ MAXIMALE

func can_execute(context: ClickContext) -> bool:
	print("\n🔍 === RESTACKACTION.CAN_EXECUTE ===")
	
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		print("❌ Pas un clic gauche")
		return false
	
	# CAS 1: Slot-to-slot classique
	if context.target_slot_index != -1:
		return _can_execute_slot_to_slot(context)
	
	# CAS 2: Main-to-slot avec même item
	if player_has_selection():
		return _can_execute_hand_to_slot_restack(context)
	
	print("❌ Ni slot-to-slot ni restack depuis main")
	return false

func execute(context: ClickContext) -> bool:
	print("\n🚀 === RESTACKACTION.EXECUTE ===")
	
	if context.target_slot_index != -1:
		return _execute_slot_to_slot_restack(context)
	else:
		return _execute_hand_to_slot_restack(context)

# === SLOT-TO-SLOT ===
func _can_execute_slot_to_slot(context: ClickContext) -> bool:
	var source_empty = context.source_slot_data.get("is_empty", true)
	var target_empty = context.target_slot_data.get("is_empty", true)
	
	if source_empty or target_empty:
		print("❌ Un slot est vide")
		return false
	
	var source_item_id = context.source_slot_data.get("item_id", "")
	var target_item_id = context.target_slot_data.get("item_id", "")
	
	if source_item_id != target_item_id or source_item_id == "":
		print("❌ Items différents (%s vs %s)" % [source_item_id, target_item_id])
		return false
	
	var item_type = context.source_slot_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		print("❌ Outil non stackable")
		return false
	
	var target_quantity = context.target_slot_data.get("quantity", 0)
	var target_max = context.target_slot_data.get("max_stack", 64)
	
	if target_quantity >= target_max:
		print("❌ Slot target plein")
		return false
	
	print("✅ Restack slot→slot possible")
	return true

func _execute_slot_to_slot_restack(context: ClickContext) -> bool:
	print("    - Restack slot→slot")
	
	var source_controller = get_controller(context.source_container_id)
	var target_controller = get_controller(context.target_container_id)
	
	if not source_controller or not target_controller:
		return false
	
	var source_slot = source_controller.inventory.get_slot(context.source_slot_index)
	var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		return false
	
	var source_quantity = source_slot.get_quantity()
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	var can_transfer = min(source_quantity, available_space)
	
	print("📊 Transfer: %d items (espace: %d)" % [can_transfer, available_space])
	
	# Transfer atomique
	target_slot.item_stack.quantity += can_transfer
	
	var remaining = source_quantity - can_transfer
	if remaining > 0:
		source_slot.item_stack.quantity = remaining
	else:
		source_slot.clear()
	
	# Signaux
	source_slot.slot_changed.emit()
	target_slot.slot_changed.emit()
	source_controller.inventory.inventory_changed.emit()
	if context.source_container_id != context.target_container_id:
		target_controller.inventory.inventory_changed.emit()
	
	# Refresh
	call_deferred("refresh_container_ui", context.source_container_id)
	if context.source_container_id != context.target_container_id:
		call_deferred("refresh_container_ui", context.target_container_id)
	
	print("✅ Restack slot→slot réussi")
	return true

# === MAIN-TO-SLOT ===
func _can_execute_hand_to_slot_restack(context: ClickContext) -> bool:
	var hand_data = get_hand_data()
	var slot_data = context.source_slot_data
	
	if slot_data.get("is_empty", true):
		print("❌ Slot cible vide")
		return false
	
	var hand_item_id = hand_data.get("item_id", "")
	var slot_item_id = slot_data.get("item_id", "")
	
	if hand_item_id != slot_item_id or hand_item_id == "":
		print("❌ Items différents main→slot")
		return false
	
	var item_type = hand_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		print("❌ Outil non stackable")
		return false
	
	var slot_quantity = slot_data.get("quantity", 0)
	var slot_max = slot_data.get("max_stack", 64)
	
	if slot_quantity >= slot_max:
		print("❌ Slot déjà plein")
		return false
	
	print("✅ Restack main→slot possible")
	return true

func _execute_hand_to_slot_restack(context: ClickContext) -> bool:
	print("    - Restack main→slot")
	
	var integrator = get_integrator()
	if not integrator:
		return false
	
	var hand_data = integrator.selected_slot_info.slot_data
	var hand_slot_index = integrator.selected_slot_info.get("slot_index", -1)
	var hand_container_id = integrator.selected_slot_info.get("container_id", "")
	var hand_quantity = hand_data.get("quantity", 0)
	
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot:
		return false
	
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	var can_transfer = min(hand_quantity, available_space)
	var remaining_in_hand = hand_quantity - can_transfer
	
	print("📊 Transfer main→slot: %d items, reste: %d" % [can_transfer, remaining_in_hand])
	
	# Transfer vers target
	target_slot.item_stack.quantity += can_transfer
	
	# CORRECTION : Retirer du slot source réel si existe
	if hand_slot_index != -1:
		var source_controller = get_controller(hand_container_id)
		if source_controller:
			var source_slot = source_controller.inventory.get_slot(hand_slot_index)
			if source_slot:
				var removed = source_slot.remove_item(can_transfer)
				if removed.quantity != can_transfer:
					# Rollback en cas d'erreur
					target_slot.item_stack.quantity -= can_transfer
					return false
	
	# Mettre à jour la sélection
	if remaining_in_hand > 0:
		update_hand_quantity(remaining_in_hand)
	else:
		clear_hand_selection()
	
	# Signaux
	target_slot.slot_changed.emit()
	target_controller.inventory.inventory_changed.emit()
	
	# Refresh
	call_deferred("refresh_container_ui", context.source_container_id)
	if hand_container_id != context.source_container_id:
		call_deferred("refresh_container_ui", hand_container_id)
	
	print("✅ Restack main→slot réussi")
	return true
