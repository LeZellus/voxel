# scripts/systems/inventory/ActionRegistry.gd - VERSION REFACTORISÉE
class_name ActionRegistry
extends RefCounted

var actions: Array[BaseInventoryAction] = []

func register(action: BaseInventoryAction):
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
	"""Configure les actions par défaut dans l'ordre de priorité"""
	register(RestackAction.new())           # Priorité 8 - Regroup stacks
	register(HandPlacementAction.new())     # Priorité 9 - Placement depuis main
	register(SimpleMoveAction.new())        # Priorité 10 - Déplacements normaux
	register(HalfStackAction.new())         # Priorité 15 - Division stacks
	register(SimpleUseAction.new())         # Priorité 20 - Utilisation items

# === ACTIONS SIMPLIFIÉES (héritent maintenant de BaseInventoryAction) ===

class SimpleMoveAction extends BaseInventoryAction:
	func _init():
		super("move", 10)
	
	func can_execute(context: ClickContext) -> bool:
		# Ne gère que les déplacements slot-à-slot normaux (pas depuis la main)
		return (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK 
				and context.target_slot_index != -1
				and context.source_slot_index != -1  # Pas depuis la main
				and not context.source_slot_data.get("is_empty", true))
	
	func execute(context: ClickContext) -> bool:
		print("🔄 [ACTION] Déplacement: slot %d -> slot %d" % [context.source_slot_index, context.target_slot_index])
		
		# Éviter déplacement sur soi-même
		if (context.source_slot_index == context.target_slot_index and 
			context.source_container_id == context.target_container_id):
			print("⚠️ Déplacement annulé (même slot)")
			return true
		
		# Récupérer les controllers
		var click_manager = get_click_manager()
		if not click_manager:
			print("❌ ClickManager introuvable")
			return false
		
		var source_controller = click_manager.get_controller_for_container(context.source_container_id)
		var target_controller = click_manager.get_controller_for_container(context.target_container_id)
		
		if not source_controller or not target_controller:
			print("❌ Controllers introuvables")
			return false
		
		var success = false
		
		# MÊME CONTAINER = déplacement interne
		if context.source_container_id == context.target_container_id:
			success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
			if success:
				Events.emit_item_moved(context.source_slot_index, context.target_slot_index, context.source_container_id)
				# NOUVEAU: Rafraîchir l'UI après le déplacement interne
				call_deferred("_refresh_ui_after_move", context.source_container_id)
		
		# CONTAINERS DIFFÉRENTS = transfert direct
		else:
			success = _execute_direct_transfer(context, source_controller, target_controller)
			if success:
				# NOUVEAU: Rafraîchir les deux UIs
				call_deferred("_refresh_ui_after_move", context.source_container_id)
				call_deferred("_refresh_ui_after_move", context.target_container_id)
		
		return success
	
	func _execute_direct_transfer(context: ClickContext, source_controller, target_controller) -> bool:
		"""TRANSFERT DIRECT entre containers différents"""
		print("🔄 Transfert réel: %s -> %s" % [context.source_container_id, context.target_container_id])
		
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
		
		return _perform_atomic_transfer(source_slot, target_slot, item, quantity)
	
	func _perform_atomic_transfer(source_slot, target_slot, item, quantity) -> bool:
		"""Transfert atomique pour éviter les états incohérents"""
		
		# CAS 1: Slot destination vide
		if target_slot.is_empty():
			print("📥 Destination vide - transfert direct")
			
			var temp_item = item
			var temp_qty = quantity
			
			source_slot.clear()
			var surplus = target_slot.add_item(temp_item, temp_qty)
			
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
				var remaining_in_source = quantity - can_transfer
				
				# LOGS DÉTAILLÉS POUR DEBUG
				print("🔍 AVANT stack:")
				print("   - Source: %d items" % source_slot.get_quantity())
				print("   - Target: %d items" % target_slot.get_quantity())
				print("   - À transférer: %d" % can_transfer)
				print("   - Restera en source: %d" % remaining_in_source)
				
				if remaining_in_source > 0:
					source_slot.item_stack.quantity = remaining_in_source
				else:
					source_slot.clear()
				
				target_slot.item_stack.quantity += can_transfer
				
				# NOUVEAU: S'assurer que les signaux sont émis
				source_slot.slot_changed.emit()
				target_slot.slot_changed.emit()
				
				print("🔍 APRÈS stack:")
				print("   - Source: %d items" % (source_slot.get_quantity() if not source_slot.is_empty() else 0))
				print("   - Target: %d items" % target_slot.get_quantity())
				
				print("✅ Stack réussi: %d items transférés" % can_transfer)
				return true
			else:
				print("❌ Stack impossible - destination pleine")
				return false
		
		# CAS 3: Items différents - swap complet
		else:
			print("🔄 Swap d'items différents")
			
			var source_item = item
			var source_qty = quantity
			var target_item = target_slot.get_item()
			var target_qty = target_slot.get_quantity()
			
			source_slot.clear()
			target_slot.clear()
			
			target_slot.add_item(source_item, source_qty)
			source_slot.add_item(target_item, target_qty)
			
			print("✅ Swap réussi: %s <-> %s" % [source_item.name, target_item.name])
			return true
	
	func _refresh_ui_after_move(container_id: String):
		"""NOUVEAU: Force le rafraîchissement de l'UI après un mouvement"""
		print("🔄 Rafraîchissement UI forcé pour: %s" % container_id)
		
		var inventory_system = ServiceLocator.get_service("inventory")
		if not inventory_system:
			print("❌ InventorySystem introuvable pour refresh")
			return
		
		var container = inventory_system.get_container(container_id)
		if not container:
			print("❌ Container introuvable: %s" % container_id)
			return
		
		if not container.ui:
			print("❌ UI introuvable pour container: %s" % container_id)
			return
		
		if container.ui.has_method("refresh_ui"):
			container.ui.refresh_ui()
			print("✅ UI rafraîchie pour: %s" % container_id)
		else:
			print("❌ Méthode refresh_ui introuvable sur UI de: %s" % container_id)
class SimpleUseAction extends BaseInventoryAction:
	func _init():
		super("use", 20)
	
	func can_execute(context: ClickContext) -> bool:
		# Clic droit sur un slot avec item, sans sélection active
		return (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK 
				and not context.source_slot_data.get("is_empty", true)
				and context.target_slot_index == -1
				and player_has_selection())  # Seulement si déjà quelque chose en main
	
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
