class SimpleUseAction extends BaseInventoryAction:
	func _init():
		super("use", 5)
	
	func can_execute(context: ClickContext) -> bool:
		var is_right_click = (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		var source_not_empty = not context.source_slot_data.get("is_empty", true)
		var no_target = (context.target_slot_index == -1)
		var no_selection = not player_has_selection()
		
		# CORRECTION : Exclure les half-stack pour laisser HalfStackAction s'en occuper
		var quantity = context.source_slot_data.get("quantity", 1)
		var is_half_stack_candidate = (quantity > 1)
		
		if is_right_click and source_not_empty and no_target and no_selection and is_half_stack_candidate:
			print("🔍 SimpleUseAction: Half-stack détecté - délégué à HalfStackAction")
			return false
		
		var result = is_right_click and source_not_empty and no_target and no_selection
		print("🔍 SimpleUseAction: %s" % ("✅" if result else "❌"))
		return result
	
	func execute(context: ClickContext) -> bool:
		var item_name = context.source_slot_data.get("item_name", "")
		print("🔨 [USE] %s" % item_name)
		return true
