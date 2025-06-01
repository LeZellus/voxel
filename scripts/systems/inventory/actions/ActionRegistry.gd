# scripts/systems/inventory/actions/ActionRegistry.gd - PRIORITÉS CORRIGÉES
class_name ActionRegistry
extends RefCounted

var actions: Array[BaseInventoryAction] = []

func register(action: BaseInventoryAction):
	actions.append(action)
	# CORRECTION : Tri par priorité DÉCROISSANTE (plus petite valeur = plus prioritaire)
	actions.sort_custom(func(a, b): return a.priority < b.priority)
	print("✅ Action enregistrée: %s (priorité: %d)" % [action.name, action.priority])

func execute(context: ClickContext) -> bool:
	print("\n🎮 === ACTIONREGISTRY.EXECUTE ===")
	print("   - Type de clic: %s" % ClickContext.ClickType.keys()[context.click_type])
	print("   - Source: %s[%d] (%s)" % [
		context.source_container_id, 
		context.source_slot_index,
		context.source_slot_data.get("item_name", "vide")
	])
	
	if context.target_slot_index != -1:
		print("   - Target: %s[%d] (%s)" % [
			context.target_container_id,
			context.target_slot_index, 
			context.target_slot_data.get("item_name", "vide")
		])
	
	print("   - Actions (ordre de priorité):")
	for i in range(actions.size()):
		var action = actions[i]
		var can_exec = action.can_execute(context)
		print("     %d. %s (p:%d) - %s" % [
			i + 1, action.name, action.priority, "✅" if can_exec else "❌"
		])
	
	# Exécuter la première action compatible
	for action in actions:
		if action.can_execute(context):
			print("🚀 EXÉCUTION: %s" % action.name)
			var result = action.execute(context)
			print("📊 RÉSULTAT: %s" % ("✅" if result else "❌"))
			return result
	
	print("⚠️ Aucune action compatible")
	return false

func setup_defaults():
	"""Actions par défaut avec NOUVELLES PRIORITÉS"""
	print("🔧 Setup actions par défaut...")
	
	# PRIORITÉS CORRIGÉES (plus petit = plus prioritaire)
	register(RestackAction.new())           # Priorité 1 - PLUS HAUTE
	register(HalfStackAction.new())         # Priorité 2
	register(HandPlacementAction.new())     # Priorité 3
	register(SimpleMoveAction.new())        # Priorité 4
	register(SimpleUseAction.new())         # Priorité 5 - PLUS BASSE
	
	print("✅ %d actions configurées" % actions.size())

# === SIMPLEMOVEACTION CORRIGÉE ===
class SimpleMoveAction extends BaseInventoryAction:
	func _init():
		super("move", 4)
	
	func can_execute(context: ClickContext) -> bool:
		var is_slot_to_slot = (context.target_slot_index != -1)
		var is_left_click = (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		var source_not_empty = not context.source_slot_data.get("is_empty", true)
		
		# CORRECTION : Exclure les cas de restack pour laisser RestackAction s'en occuper
		if is_slot_to_slot and source_not_empty:
			var target_not_empty = not context.target_slot_data.get("is_empty", true)
			if target_not_empty:
				var same_item = (context.source_slot_data.get("item_id", "") == 
								context.target_slot_data.get("item_id", ""))
				var is_stackable = (context.source_slot_data.get("item_type", -1) != Item.ItemType.TOOL)
				
				if same_item and is_stackable:
					print("🔍 SimpleMoveAction: Restack détecté - délégué à RestackAction")
					return false
		
		var result = is_left_click and is_slot_to_slot and source_not_empty
		print("🔍 SimpleMoveAction: %s" % ("✅" if result else "❌"))
		return result
	
	func execute(context: ClickContext) -> bool:
		print("🔄 [MOVE] %s[%d] → %s[%d]" % [
			context.source_container_id, context.source_slot_index,
			context.target_container_id, context.target_slot_index
		])
		
		var source_controller = get_controller(context.source_container_id)
		var target_controller = get_controller(context.target_container_id)
		
		if not source_controller or not target_controller:
			return false
		
		var success = false
		
		if context.source_container_id == context.target_container_id:
			# Même container
			success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
		else:
			# Containers différents
			success = _transfer_between_containers(context, source_controller, target_controller)
		
		if success:
			call_deferred("refresh_container_ui", context.source_container_id)
			if context.source_container_id != context.target_container_id:
				call_deferred("refresh_container_ui", context.target_container_id)
		
		return success
	
	func _transfer_between_containers(context: ClickContext, source_ctrl, target_ctrl) -> bool:
		var source_slot = source_ctrl.inventory.get_slot(context.source_slot_index)
		var target_slot = target_ctrl.inventory.get_slot(context.target_slot_index)
		
		if not source_slot or not target_slot:
			return false
		
		var item = source_slot.get_item()
		var quantity = source_slot.get_quantity()
		
		if target_slot.is_empty():
			# Transfer direct
			source_slot.clear()
			target_slot.add_item(item, quantity)
		else:
			# Swap
			var target_item = target_slot.get_item()
			var target_qty = target_slot.get_quantity()
			
			source_slot.clear()
			target_slot.clear()
			
			target_slot.add_item(item, quantity)
			source_slot.add_item(target_item, target_qty)
		
		return true

# === SIMPLEUSEACTION CORRIGÉE ===
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
