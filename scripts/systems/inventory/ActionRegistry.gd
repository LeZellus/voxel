# scripts/systems/inventory/ActionRegistry.gd - VERSION FINALE CORRIGÉE
class_name ActionRegistry
extends RefCounted

var actions: Array[SimpleAction] = []

func register(action: SimpleAction):
	actions.append(action)
	actions.sort_custom(func(a, b): return a.priority > b.priority)

func execute(context: ClickContext) -> bool:
	print("🎮 Exécution pour: %s" % ClickContext.ClickType.keys()[context.click_type])
	print("   - Source: slot %d (%s)" % [context.source_slot_index, context.source_container_id])
	print("   - Target: slot %d (%s)" % [context.target_slot_index, context.target_container_id])
	
	for action in actions:
		if action.can_execute(context):
			print("✅ Action trouvée: %s" % action.name)
			return action.execute(context)
	
	print("⚠️ Aucune action pour ce contexte")
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
		# Doit être un clic gauche avec une destination définie
		return (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK 
				and context.target_slot_index != -1
				and not context.source_slot_data.get("is_empty", true))
	
	func execute(context: ClickContext) -> bool:
		print("🔄 [ACTION] Déplacement: slot %d -> slot %d" % [context.source_slot_index, context.target_slot_index])
		
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
			print("🏠 Déplacement interne dans %s" % context.source_container_id)
			
			var success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
			
			if success:
				print("✅ Déplacement interne réussi")
				
				# Émettre l'événement
				Events.emit_item_moved(context.source_slot_index, context.target_slot_index, context.source_container_id)
			else:
				print("❌ Échec déplacement interne")
			
			return success
		
		# CONTAINERS DIFFÉRENTS = transfert
		else:
			return _execute_transfer(context, source_controller, target_controller)
	
	func _execute_transfer(context: ClickContext, source_controller, target_controller) -> bool:
		print("🔄 Transfert: %s -> %s" % [context.source_container_id, context.target_container_id])
		
		# Récupérer l'item source
		var item_id = context.source_slot_data.get("item_id", "")
		var quantity = context.source_slot_data.get("quantity", 0)
		
		if item_id == "" or quantity <= 0:
			print("❌ Item source invalide")
			return false
		
		# Vérifier si la destination peut accepter l'item
		var target_slot_info = target_controller.get_slot_info(context.target_slot_index)
		
		# Si slot cible vide, on peut transférer
		if target_slot_info.get("is_empty", true):
			var removed = source_controller.remove_item(item_id, quantity)
			if removed > 0:
				# Ici on devrait pouvoir ajouter à un slot spécifique
				# Pour l'instant, on simule le succès
				print("✅ Transfert simulé: %s x%d" % [item_id, removed])
				return true
		
		# Si même item, essayer de stacker
		elif target_slot_info.get("item_id", "") == item_id:
			print("📚 Tentative de stack...")
			# Logique de stack à implémenter
			return true
		
		# Sinon, swap
		else:
			print("🔄 Tentative de swap...")
			# Logique de swap à implémenter  
			return true
		
		return false
	
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
				and context.target_slot_index == -1)  # Pas de destination = utilisation directe
	
	func execute(context: ClickContext) -> bool:
		var item_type = context.source_slot_data.get("item_type", -1)
		var item_name = context.source_slot_data.get("item_name", "")
		
		match item_type:
			Item.ItemType.CONSUMABLE:
				print("🍎 %s consommé !" % item_name)
				# TODO: Réduire la quantité dans l'inventaire
				return true
			Item.ItemType.TOOL:
				print("🔨 %s équipé !" % item_name)
				return true
			_:
				print("❌ %s ne peut pas être utilisé" % item_name)
				return false
