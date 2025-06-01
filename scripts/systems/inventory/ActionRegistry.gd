# scripts/systems/inventory/ActionRegistry.gd - VERSION SANS DOUBLE RETRAIT
class_name ActionRegistry
extends RefCounted

var actions: Array[SimpleAction] = []

func register(action: SimpleAction):
	actions.append(action)
	actions.sort_custom(func(a, b): return a.priority > b.priority)

func execute(context: ClickContext) -> bool:
	print("🎮 Exécution pour: %s" % ClickContext.ClickType.keys()[context.click_type])
	
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
	
	func can_execute(_context: ClickContext) -> bool:
		return false
	
	func execute(_context: ClickContext) -> bool:
		return false

class SimpleMoveAction extends SimpleAction:
	func _init():
		super("move", 10)
	
	func can_execute(context: ClickContext) -> bool:
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
			var success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
			if success:
				Events.emit_item_moved(context.source_slot_index, context.target_slot_index, context.source_container_id)
			return success
		
		# CONTAINERS DIFFÉRENTS = transfert direct
		else:
			return _execute_direct_transfer(context, source_controller, target_controller)
	
	func _execute_direct_transfer(context: ClickContext, source_controller, target_controller) -> bool:
		"""TRANSFERT DIRECT - utilise move_item_to pour éviter les doubles retraits"""
		print("🔄 Transfert réel: %s -> %s" % [context.source_container_id, context.target_container_id])
		
		# Récupérer les slots directement
		var source_slot = source_controller.inventory.get_slot(context.source_slot_index)
		var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
		
		if not source_slot or not target_slot:
			print("❌ Slots introuvables")
			return false
		
		if source_slot.is_empty():
			print("❌ Slot source vide")
			return false
		
		var item = source_slot.get_item()
		var quantity = source_slot.get_quantity()
		
		print("📦 Transfert: %s x%d de %s[%d] vers %s[%d]" % [
			item.name, quantity,
			context.source_container_id, context.source_slot_index,
			context.target_container_id, context.target_slot_index
		])
		
		# TRANSFERT DIRECT SANS DOUBLE MANIPULATION
		return _perform_atomic_transfer(source_slot, target_slot, item, quantity)
	
	func _perform_atomic_transfer(source_slot, target_slot, item, quantity) -> bool:
		"""Transfert atomique pour éviter les états incohérents"""
		
		print("🔄 Transfert atomique: %s x%d" % [item.name, quantity])
		
		# CAS 1: Slot destination vide
		if target_slot.is_empty():
			print("📥 Destination vide - transfert direct")
			
			# OPÉRATION ATOMIQUE : Sauvegarder puis manipuler
			var temp_item = item
			var temp_qty = quantity
			
			# Vider la source PUIS remplir la destination
			source_slot.clear()
			var surplus = target_slot.add_item(temp_item, temp_qty)
			
			# Gérer le surplus
			if surplus > 0:
				source_slot.add_item(temp_item, surplus)
				print("⚠️ Transfert partiel: %d/%d (surplus: %d)" % [temp_qty - surplus, temp_qty, surplus])
			else:
				print("✅ Transfert complet: %s x%d" % [temp_item.name, temp_qty])
			
			return true
		
		# CAS 2: Même item - tentative de stack
		elif target_slot.get_item().id == item.id and item.is_stackable:
			print("📚 Tentative de stack...")
			
			var available_space = target_slot.get_max_stack_size() - target_slot.get_quantity()
			var can_transfer = min(quantity, available_space)
			
			if can_transfer > 0:
				# Transfert atomique pour le stack
				var remaining_in_source = quantity - can_transfer
				
				# Mise à jour atomique des quantités
				if remaining_in_source > 0:
					source_slot.item_stack.quantity = remaining_in_source
				else:
					source_slot.clear()
				
				target_slot.item_stack.quantity += can_transfer
				
				# Déclencher les signaux
				source_slot.slot_changed.emit()
				target_slot.slot_changed.emit()
				
				print("✅ Stack réussi: %d items transférés" % can_transfer)
				return true
			else:
				print("❌ Stack impossible - destination pleine")
				return false
		
		# CAS 3: Items différents - swap complet
		else:
			print("🔄 Swap d'items différents")
			
			# Sauvegarder les données avant manipulation
			var source_item = item
			var source_qty = quantity
			var target_item = target_slot.get_item()
			var target_qty = target_slot.get_quantity()
			
			# Swap atomique : vider puis remplir
			source_slot.clear()
			target_slot.clear()
			
			var surplus1 = target_slot.add_item(source_item, source_qty)
			var surplus2 = source_slot.add_item(target_item, target_qty)
			
			# En principe, pas de surplus pour un swap 1:1
			if surplus1 > 0 or surplus2 > 0:
				print("⚠️ Surplus inattendu dans swap")
			
			print("✅ Swap réussi: %s <-> %s" % [source_item.name, target_item.name])
			return true		
	func _find_click_manager():
		return ServiceLocator.get_service("click_system")
		
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
				return true
			Item.ItemType.TOOL:
				print("🔨 %s équipé !" % item_name)
				return true
			_:
				print("❌ %s ne peut pas être utilisé" % item_name)
				return false
