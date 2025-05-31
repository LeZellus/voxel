# scripts/click_system/actions/MoveItemAction.gd
class_name MoveItemAction
extends ClickAction

var system_manager: ClickSystemManager

func _init(manager: ClickSystemManager):
	system_manager = manager
	action_name = "move_item"
	can_undo = true

func can_execute(context: ClickContext) -> bool:
	# Cette action nécessite un slot source avec un item
	if not validate_source_slot(context):
		return false
	
	if not validate_has_source_item(context):
		return false
	
	# Pour les clics simples, démarrer l'attente d'une cible
	if context.target_slot_index == -1:
		return true
	
	# Pour les slot-to-slot, valider la cible
	if not validate_target_slot(context):
		return false
	
	return true

func execute(context: ClickContext) -> bool:
	log_action(context, "Début du déplacement")
	
	# Cas 1: Clic simple - démarrer l'attente d'une cible
	if context.target_slot_index == -1:
		system_manager.start_waiting_for_target(context)
		log_action(context, "En attente d'une destination")
		emit_action_signals(context, true)
		return true
	
	# Cas 2: Slot-to-slot - exécuter le déplacement
	return _execute_move(context)

func _execute_move(context: ClickContext) -> bool:
	"""Exécute le déplacement effectif entre deux slots"""
	var source_controller = get_source_controller(context, system_manager)
	var target_controller = get_target_controller(context, system_manager)
	
	if not source_controller or not target_controller:
		log_action(context, "Contrôleurs introuvables")
		emit_action_signals(context, false)
		return false
	
	var success = false
	
	# Même conteneur - utiliser move_item
	if not context.is_cross_container:
		success = source_controller.move_item(context.source_slot_index, context.target_slot_index)
		log_action(context, "Déplacement dans le même conteneur: %s" % str(success))
	
	# Cross-container - logique plus complexe
	else:
		success = _execute_cross_container_move(context, source_controller, target_controller)
		log_action(context, "Déplacement cross-container: %s" % str(success))
	
	emit_action_signals(context, success)
	return success

func _execute_cross_container_move(context: ClickContext, source_ctrl, target_ctrl) -> bool:
	"""Gère le déplacement entre conteneurs différents"""
	
	# Récupérer les inventaires
	var source_inventory = source_ctrl.inventory
	var target_inventory = target_ctrl.inventory
	
	var source_slot = source_inventory.get_slot(context.source_slot_index)
	var target_slot = target_inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		return false
	
	if source_slot.is_empty():
		return false
	
	var item = source_slot.get_item()
	var quantity = source_slot.get_quantity()
	
	# Cas 1: Slot cible vide
	if target_slot.is_empty():
		var removed_stack = source_slot.remove_item(quantity)
		if removed_stack.quantity > 0:
			var surplus = target_slot.add_item(item, removed_stack.quantity)
			
			# Remettre le surplus si nécessaire
			if surplus > 0:
				source_slot.add_item(item, surplus)
			
			return removed_stack.quantity > surplus
	
	# Cas 2: Items identiques (stack)
	elif target_slot.can_accept_item(item, quantity):
		var can_add = item.max_stack_size - target_slot.get_quantity()
		var to_transfer = min(quantity, can_add)
		
		if to_transfer > 0:
			var removed_stack = source_slot.remove_item(to_transfer)
			if removed_stack.quantity > 0:
				target_slot.add_item(item, removed_stack.quantity)
				return true
	
	# Cas 3: Swap (échange)
	else:
		var target_item = target_slot.get_item()
		var target_quantity = target_slot.get_quantity()
		
		# Vider les deux slots
		source_slot.clear()
		target_slot.clear()
		
		# Échanger
		target_slot.add_item(item, quantity)
		source_slot.add_item(target_item, target_quantity)
		
		return true
	
	return false

func get_description(context: ClickContext) -> String:
	if context.target_slot_index == -1:
		return "Sélectionner l'item à déplacer"
	else:
		return "Déplacer l'item du slot %d vers le slot %d" % [context.source_slot_index, context.target_slot_index]

func get_feedback_message(context: ClickContext, success: bool) -> String:
	if success:
		if context.target_slot_index == -1:
			return "Item sélectionné - cliquez sur la destination"
		else:
			return "Item déplacé avec succès"
	else:
		return "Impossible de déplacer l'item"
