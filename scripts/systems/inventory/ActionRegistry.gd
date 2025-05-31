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
		return context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK
	
	func execute(context: ClickContext) -> bool:
		# Premier clic = sélectionner source
		if context.target_slot_index == -1:
			var click_manager = _find_click_manager()
			if click_manager:
				print("📌 Item sélectionné slot %d - cliquez destination" % context.source_slot_index)
				click_manager.start_waiting_for_target(context)
				return true
			return false
		
		# Deuxième clic = déplacer vers destination
		return _execute_move(context)
	
	func _execute_move(context: ClickContext) -> bool:
		print("🔄 Déplacement: slot %d -> slot %d" % [context.source_slot_index, context.target_slot_index])
		
		# Éviter déplacement sur soi-même
		if (context.source_slot_index == context.target_slot_index and 
			context.source_container_id == context.target_container_id):
			print("⚠️ Déplacement annulé (même slot)")
			return true
		
		# Récupérer les controllers
		var click_manager = _find_click_manager()
		if not click_manager:
			print("❌ ClickManager introuvable")
			return false
		
		var source_controller = click_manager.get_controller_for_container(context.source_container_id)
		var target_controller = click_manager.get_controller_for_container(context.target_container_id)
		
		if not source_controller or not target_controller:
			print("❌ Controllers introuvables")
			return false
		
		# MÊME CONTAINER = déplacement interne
		if context.source_container_id == context.target_container_id:
			var success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
			if success:
				print("✅ Item déplacé dans %s" % context.source_container_id)
			else:
				print("❌ Échec déplacement interne")
			return success
		
		# CONTAINERS DIFFÉRENTS = transfert
		else:
			return _execute_transfer(context, source_controller, target_controller)
	
	func _execute_transfer(context: ClickContext, source_controller, target_controller) -> bool:
		print("🔄 Transfert: %s -> %s" % [context.source_container_id, context.target_container_id])
		
		# Récupérer l'item source
		var source_slot_info = source_controller.get_slot_info(context.source_slot_index)
		if source_slot_info.get("is_empty", true):
			print("❌ Slot source vide")
			return false
		
		var item_id = source_slot_info.get("item_id", "")
		var quantity = source_slot_info.get("quantity", 0)
		
		if item_id == "" or quantity <= 0:
			print("❌ Item invalide")
			return false
		
		# Retirer de la source
		var removed = source_controller.remove_item(item_id, quantity)
		if removed <= 0:
			print("❌ Impossible de retirer l'item")
			return false
		
		print("✅ Transfert réussi: %s x%d" % [item_id, removed])
		return true
	
	func _find_click_manager():
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
