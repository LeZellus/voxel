# scripts/inventory/click_system/core/ActionRegistry.gd - NOUVEAU
class_name ActionRegistry
extends RefCounted

var actions: Array[SimpleAction] = []

func register(action: SimpleAction):
	actions.append(action)
	actions.sort_custom(func(a, b): return a.priority > b.priority)

func execute(context: ClickContext) -> bool:
	for action in actions:
		if action.can_execute(context):
			print("🎮 Exécution: %s" % action.name)
			return action.execute(context)
	
	print("⚠️ Aucune action pour: %s" % ClickContext.ClickType.keys()[context.click_type])
	return false

func setup_defaults():
	register(SimpleMoveAction.new())
	register(SimpleUseAction.new())

# === ACTIONS SIMPLIFIÉES ===
class SimpleAction:
	var name: String
	var priority: int
	
	func _init(action_name: String, action_priority: int = 0):
		name = action_name
		priority = action_priority
	
	func can_execute(context: ClickContext) -> bool:
		return false
	
	func execute(context: ClickContext) -> bool:
		return false

class SimpleMoveAction extends SimpleAction:
	func _init():
		super("move", 10)
	
	func can_execute(context: ClickContext) -> bool:
		# CORRECTION: Accepter même les slots vides pour la sélection de destination
		return context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK
	
	func execute(context: ClickContext) -> bool:
		# Clic simple = attendre destination
		if context.target_slot_index == -1:
			var click_manager = _find_click_manager()
			if click_manager:
				click_manager.start_waiting_for_target(context)
				print("⏳ En attente de destination")
				return true
			return false
		
		# Slot-to-slot = déplacer (logique simplifiée pour l'instant)
		print("🔄 Move: slot %d -> slot %d" % [context.source_slot_index, context.target_slot_index])
		return true  # TODO: implémenter le déplacement réel
	
	func _find_click_manager():
		# Cherche dans la scène courante
		var scene = Engine.get_main_loop().current_scene
		return _find_click_manager_recursive(scene)
	
	func _find_click_manager_recursive(node: Node):
		if node.get_script() and node.get_script().get_global_name() == "ClickSystemManager":
			return node
		
		for child in node.get_children():
			var result = _find_click_manager_recursive(child)
			if result:
				return result
		return null

class SimpleUseAction extends SimpleAction:
	func _init():
		super("use", 20)
	
	func can_execute(context: ClickContext) -> bool:
		return (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK 
				and not context.source_slot_data.get("is_empty", true)
				and context.target_slot_index == -1)
	
	func execute(context: ClickContext) -> bool:
		var item_type = context.source_slot_data.get("item_type", -1)
		var item_name = context.source_slot_data.get("item_name", "")
		
		match item_type:
			Item.ItemType.CONSUMABLE:
				print("🍎 %s consommé !" % item_name)
				return true  # TODO: implémenter la consommation réelle
			Item.ItemType.TOOL:
				print("🔨 %s équipé !" % item_name)
				return true
			_:
				print("❌ Type non supporté: %s" % item_name)
				return false
