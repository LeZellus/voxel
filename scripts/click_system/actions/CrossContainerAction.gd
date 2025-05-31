# scripts/click_system/actions/CrossContainerAction.gd
class_name CrossContainerAction
extends ClickAction

var system_manager: ClickSystemManager

func _init(manager: ClickSystemManager):
	system_manager = manager
	action_name = "cross_container_move"
	can_undo = true

func can_execute(context: ClickContext) -> bool:
	# Cette action ne fonctionne QUE sur les slot-to-slot cross-container
	if context.target_slot_index == -1:
		return false  # Pas de clic simple
	
	if not context.is_cross_container:
		return false  # Pas de cross-container
	
	if not validate_source_slot(context):
		return false
	
	if not validate_target_slot(context):
		return false
	
	if not validate_has_source_item(context):
		return false
	
	# Vérifier que les containers existent
	var source_controller = get_source_controller(context, system_manager)
	var target_controller = get_target_controller(context, system_manager)
	
	if not source_controller or not target_controller:
		return false
	
	return true

func execute(context: ClickContext) -> bool:
	log_action(context, "Début du transfert cross-container")
	
	var source_controller = get_source_controller(context, system_manager)
	var target_controller = get_target_controller(context, system_manager)
	
	if not source_controller or not target_controller:
		log_action(context, "Contrôleurs introuvables")
		emit_action_signals(context, false)
		return false
	
	var success = _execute_cross_transfer(context, source_controller, target_controller)
	
	log_action(context, "Transfert cross-container: %s" % str(success))
	emit_action_signals(context, success)
	return success

func _execute_cross_transfer(context: ClickContext, source_ctrl, target_ctrl) -> bool:
	"""Gère le transfert entre conteneurs différents"""
	
	# Récupérer les inventaires via les contrôleurs
	var source_inventory = source_ctrl.inventory
	var target_inventory = target_ctrl.inventory
	
	var source_slot = source_inventory.get_slot(context.source_slot_index)
	var target_slot = target_inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		log_action(context, "Slots introuvables")
		return false
	
	if source_slot.is_empty():
		log_action(context, "Slot source vide")
		return false
	
	var item = source_slot.get_item()
	var quantity = source_slot.get_quantity()
	
	log_action(context, "Transfert: %s x%d" % [item.name, quantity])
	
	# Cas 1: Slot cible vide - transfert simple
	if target_slot.is_empty():
		return _transfer_to_empty_slot(context, source_slot, target_slot, item, quantity)
	
	# Cas 2: Items identiques - stack
	elif target_slot.can_accept_item(item, quantity):
		return _stack_items(context, source_slot, target_slot, item, quantity)
	
	# Cas 3: Items différents - swap
	else:
		return _swap_items(context, source_slot, target_slot, item, quantity)

func _transfer_to_empty_slot(context: ClickContext, source_slot, target_slot, item: Item, quantity: int) -> bool:
	"""Transfère vers un slot vide"""
	log_action(context, "Transfert vers slot vide")
	
	var removed_stack = source_slot.remove_item(quantity)
	if removed_stack.quantity > 0:
		var surplus = target_slot.add_item(item, removed_stack.quantity)
		
		# Remettre le surplus si nécessaire
		if surplus > 0:
			source_slot.add_item(item, surplus)
			log_action(context, "Surplus remis: %d" % surplus)
		
		var transferred = removed_stack.quantity - surplus
		log_action(context, "✅ Transféré: %d items" % transferred)
		return transferred > 0
	
	return false

func _stack_items(context: ClickContext, source_slot, target_slot, item: Item, quantity: int) -> bool:
	"""Stack des items identiques"""
	log_action(context, "Stack d'items identiques")
	
	var can_add = item.max_stack_size - target_slot.get_quantity()
	var to_transfer = min(quantity, can_add)
	
	if to_transfer > 0:
		var removed_stack = source_slot.remove_item(to_transfer)
		if removed_stack.quantity > 0:
			target_slot.add_item(item, removed_stack.quantity)
			log_action(context, "✅ Stacké: %d items" % removed_stack.quantity)
			return true
	
	log_action(context, "❌ Impossible de stacker")
	return false

func _swap_items(context: ClickContext, source_slot, target_slot, item: Item, quantity: int) -> bool:
	"""Échange les items entre slots"""
	log_action(context, "Échange d'items")
	
	var target_item = target_slot.get_item()
	var target_quantity = target_slot.get_quantity()
	
	# Vider les deux slots
	source_slot.clear()
	target_slot.clear()
	
	# Échanger
	target_slot.add_item(item, quantity)
	source_slot.add_item(target_item, target_quantity)
	
	log_action(context, "✅ Échange réussi: %s ↔ %s" % [item.name, target_item.name])
	return true

func get_description(context: ClickContext) -> String:
	return "Transfert cross-container: %s[%d] → %s[%d]" % [
		context.source_container_id,
		context.source_slot_index,
		context.target_container_id,
		context.target_slot_index
	]

func get_feedback_message(context: ClickContext, success: bool) -> String:
	if success:
		return "Item transféré entre conteneurs"
	else:
		return "Impossible de transférer l'item"
