class_name SimpleMoveAction
extends BaseInventoryAction

func _init():
	super("move", 4)

func can_execute(context: ClickContext) -> bool:
	# Seulement slot-to-slot, clic gauche, source non vide
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		return false
	if context.target_slot_index == -1:
		return false
	if context.source_slot_data.get("is_empty", true):
		return false
	
	# Ne PAS traiter les restacks (déléguer à RestackAction)
	if not context.target_slot_data.get("is_empty", true):
		var same_item = (context.source_slot_data.get("item_id", "") == 
						context.target_slot_data.get("item_id", ""))
		if same_item:
			return false  # Laisser RestackAction s'en occuper
	
	return true

func execute(context: ClickContext) -> bool:
	var source_ctrl = get_controller(context.source_container_id)
	var target_ctrl = get_controller(context.target_container_id)
	
	if not source_ctrl or not target_ctrl:
		return false
	
	# Transaction atomique
	var tx = InventoryTransaction.new()
	
	if context.target_slot_data.get("is_empty", true):
		# Déplacement simple
		tx.add_move(
			source_ctrl, context.source_slot_index,
			target_ctrl, context.target_slot_index
		)
	else:
		# Swap
		tx.add_swap(
			source_ctrl, context.source_slot_index,
			target_ctrl, context.target_slot_index
		)
	
	return tx.execute()
