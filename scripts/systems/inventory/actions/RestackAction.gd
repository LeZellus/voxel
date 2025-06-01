class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 1)

func can_execute(context: ClickContext) -> bool:
	# Uniquement pour clic gauche
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		return false
	
	# Cas 1: Slot vers slot avec même item
	if context.target_slot_index != -1:
		return _can_restack_slots(context)
	
	# Cas 2: Main vers slot avec même item
	if player_has_selection():
		return _can_restack_from_hand(context)
	
	return false

func execute(context: ClickContext) -> bool:
	if context.target_slot_index != -1:
		return _execute_slot_restack(context)
	else:
		return _execute_hand_restack(context)

# --- Méthodes privées ---

func _can_restack_slots(context: ClickContext) -> bool:
	# Vérifications de base
	if context.source_slot_data.get("is_empty", true):
		return false
	if context.target_slot_data.get("is_empty", true):
		return false
	
	# Même item et stackable
	var source_id = context.source_slot_data.get("item_id", "")
	var target_id = context.target_slot_data.get("item_id", "")
	
	if source_id != target_id or source_id == "":
		return false
	
	# Vérifier stackability
	var item_type = context.source_slot_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		return false
	
	# Vérifier l'espace disponible
	var target_qty = context.target_slot_data.get("quantity", 0)
	var target_max = context.target_slot_data.get("max_stack", 64)
	
	return target_qty < target_max

func _can_restack_from_hand(context: ClickContext) -> bool:
	var hand_data = get_hand_data()
	var slot_data = context.source_slot_data
	
	# Slot cible doit avoir le même item
	if slot_data.get("is_empty", true):
		return false
	
	var hand_id = hand_data.get("item_id", "")
	var slot_id = slot_data.get("item_id", "")
	
	if hand_id != slot_id or hand_id == "":
		return false
	
	# Vérifier stackability et espace
	var item_type = hand_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		return false
	
	var slot_qty = slot_data.get("quantity", 0)
	var slot_max = slot_data.get("max_stack", 64)
	
	return slot_qty < slot_max

func _execute_slot_restack(context: ClickContext) -> bool:
	var source_ctrl = get_controller(context.source_container_id)
	var target_ctrl = get_controller(context.target_container_id)
	
	if not source_ctrl or not target_ctrl:
		return false
	
	# Transaction atomique
	var tx = InventoryTransaction.new()
	tx.add_restack(
		source_ctrl, context.source_slot_index,
		target_ctrl, context.target_slot_index
	)
	
	return tx.execute()

func _execute_hand_restack(context: ClickContext) -> bool:
	var integrator = get_integrator()
	if not integrator:
		return false
	
	var hand_info = integrator.selected_slot_info
	var target_ctrl = get_controller(context.source_container_id)
	
	if not target_ctrl:
		return false
	
	# Transaction atomique avec gestion main
	var tx = InventoryTransaction.new()
	tx.add_hand_restack(
		hand_info,
		target_ctrl, context.source_slot_index
	)
	
	var success = tx.execute()
	
	if success:
		# Mettre à jour ou nettoyer la sélection
		var remaining = tx.get_remaining_in_hand()
		if remaining > 0:
			update_hand_quantity(remaining)
		else:
			clear_hand_selection()
	
	return success
