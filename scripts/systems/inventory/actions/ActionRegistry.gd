# scripts/systems/inventory/ActionRegistry.gd - VERSION AVEC PRIORITÉS CORRIGÉES
class_name ActionRegistry
extends RefCounted

var actions: Array[BaseInventoryAction] = []

func register(action: BaseInventoryAction):
	actions.append(action)
	# CORRECTION: Tri par priorité DÉCROISSANTE (plus haute priorité = plus petite valeur)
	actions.sort_custom(func(a, b): return a.priority < b.priority)
	print("✅ Action enregistrée: %s (priorité: %d)" % [action.name, action.priority])

func execute(context: ClickContext) -> bool:
	print("\n🎮 === ACTIONREGISTRY.EXECUTE ===")
	print("   - Type de clic: %s" % ClickContext.ClickType.keys()[context.click_type])
	print("   - Actions disponibles: %d" % actions.size())
	
	# DEBUG: Lister toutes les actions DANS L'ORDRE DE PRIORITÉ
	for i in range(actions.size()):
		var action = actions[i]
		var can_exec = action.can_execute(context)
		print("   %d. %s (priorité: %d) - Peut exécuter: %s" % [
			i + 1, action.name, action.priority, "✅" if can_exec else "❌"
		])
	
	# Exécuter la première action compatible (ordre de priorité)
	for action in actions:
		if action.can_execute(context):
			print("🚀 EXÉCUTION: %s (priorité: %d)" % [action.name, action.priority])
			var result = action.execute(context)
			print("📊 RÉSULTAT: %s" % ("✅ Succès" if result else "❌ Échec"))
			return result
	
	print("⚠️ Aucune action compatible trouvée")
	return false

func setup_defaults():
	"""Configure les actions par défaut dans l'ordre de priorité"""
	print("\n🔧 === SETUP ACTIONS PAR DÉFAUT ===")
	# NOUVELLES PRIORITÉS LOGIQUES (plus petit = plus prioritaire)
	register(RestackAction.new())           # Priorité 1 - PLUS HAUTE PRIORITÉ
	register(HalfStackAction.new())         # Priorité 2 - Avant les autres actions
	register(HandPlacementAction.new())     # Priorité 3 - Placement depuis main
	register(SimpleMoveAction.new())        # Priorité 4 - Déplacements normaux
	register(SimpleUseAction.new())         # Priorité 5 - PLUS BASSE PRIORITÉ
	
	print("✅ %d actions configurées" % actions.size())
	print("📋 Ordre final:")
	for i in range(actions.size()):
		print("   %d. %s (priorité: %d)" % [i + 1, actions[i].name, actions[i].priority])

# === ACTIONS SIMPLIFIÉES AVEC NOUVELLES PRIORITÉS ===

class SimpleMoveAction extends BaseInventoryAction:
	func _init():
		super("move", 4)  # NOUVELLE PRIORITÉ
	
	func can_execute(context: ClickContext) -> bool:
		# VALIDATION PLUS STRICTE pour éviter les conflits avec RestackAction
		var is_slot_to_slot = (context.target_slot_index != -1 and context.source_slot_index != -1)
		var is_left_click = (context.click_type == ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		var source_not_empty = not context.source_slot_data.get("is_empty", true)
		
		# NOUVELLE CONDITION: Ne pas prendre si c'est un restack potentiel
		var is_restack_scenario = false
		if is_slot_to_slot and is_left_click and source_not_empty:
			# Vérifier si c'est un restack (même item)
			var target_not_empty = not context.target_slot_data.get("is_empty", true)
			if target_not_empty:
				var source_item_id = context.source_slot_data.get("item_id", "")
				var target_item_id = context.target_slot_data.get("item_id", "")
				var source_item_type = context.source_slot_data.get("item_type", -1)
				
				if (source_item_id == target_item_id and source_item_id != "" and source_item_type != Item.ItemType.TOOL):
					is_restack_scenario = true
					print("🔍 SimpleMoveAction: Détection scénario restack - délégué à RestackAction")
		
		var result = is_left_click and is_slot_to_slot and source_not_empty and not is_restack_scenario
		
		if result:
			print("🔍 SimpleMoveAction: ✅ Peut exécuter")
		else:
			print("🔍 SimpleMoveAction: ❌ Ne peut pas exécuter")
			print("     - Click type OK: %s" % is_left_click)
			print("     - Slot to slot: %s" % is_slot_to_slot)
			print("     - Source pas vide: %s" % source_not_empty)
			print("     - Pas un restack: %s" % (not is_restack_scenario))
		
		return result
	
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
				call_deferred("_refresh_ui_after_move", context.source_container_id)
		
		# CONTAINERS DIFFÉRENTS = transfert direct
		else:
			success = _execute_direct_transfer(context, source_controller, target_controller)
			if success:
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
		
		# CAS 2: Même item - DÉLÉGUER À RESTACKACTION
		elif target_slot.get_item().id == item.id and item.is_stackable:
			print("📚 Détection restack - ne devrait pas arriver ici!")
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
		"""Force le rafraîchissement de l'UI après un mouvement"""
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
		super("use", 5)  # NOUVELLE PRIORITÉ - PLUS BASSE
	
	func can_execute(context: ClickContext) -> bool:
		# CONDITION PLUS STRICTE: Seulement si pas de sélection active ET pas de half-stack potentiel
		var is_right_click = (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		var source_not_empty = not context.source_slot_data.get("is_empty", true)
		var no_target = (context.target_slot_index == -1)
		var no_selection = not player_has_selection()
		
		# NOUVELLE CONDITION: Éviter si c'est un half-stack potentiel (quantité > 1)
		var quantity = context.source_slot_data.get("quantity", 1)
		var item_type = context.source_slot_data.get("item_type", -1)
		var is_half_stack_scenario = (quantity > 1 and item_type != Item.ItemType.TOOL)
		
		var result = is_right_click and source_not_empty and no_target and no_selection and not is_half_stack_scenario
		
		if result:
			print("🔍 SimpleUseAction: ✅ Peut exécuter")
		else:
			print("🔍 SimpleUseAction: ❌ Ne peut pas exécuter")
			print("     - Clic droit: %s" % is_right_click)
			print("     - Source pas vide: %s" % source_not_empty)
			print("     - Pas de target: %s" % no_target)
			print("     - Pas de sélection: %s" % no_selection)
			print("     - Pas half-stack scenario: %s" % (not is_half_stack_scenario))
		
		return result
	
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
