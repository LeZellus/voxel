class_name InventoryTransaction
extends RefCounted

# Gestion transactionnelle pour garantir l'atomicité

var operations: Array = []
var remaining_in_hand: int = 0

func add_move(source_ctrl, source_idx: int, target_ctrl, target_idx: int):
	operations.append({
		"type": "move",
		"source_ctrl": source_ctrl,
		"source_idx": source_idx,
		"target_ctrl": target_ctrl,
		"target_idx": target_idx
	})

func add_swap(source_ctrl, source_idx: int, target_ctrl, target_idx: int):
	operations.append({
		"type": "swap",
		"source_ctrl": source_ctrl,
		"source_idx": source_idx,
		"target_ctrl": target_ctrl,
		"target_idx": target_idx
	})

func add_restack(source_ctrl, source_idx: int, target_ctrl, target_idx: int):
	operations.append({
		"type": "restack",
		"source_ctrl": source_ctrl,
		"source_idx": source_idx,
		"target_ctrl": target_ctrl,
		"target_idx": target_idx
	})

func add_hand_restack(hand_info: Dictionary, target_ctrl, target_idx: int):
	operations.append({
		"type": "hand_restack",
		"hand_info": hand_info,
		"target_ctrl": target_ctrl,
		"target_idx": target_idx
	})

func execute() -> bool:
	# Valider toutes les opérations d'abord
	for op in operations:
		if not _validate_operation(op):
			return false
	
	# Exécuter les opérations
	for op in operations:
		if not _execute_operation(op):
			# En cas d'échec, on pourrait faire un rollback
			return false
	
	# Émettre les signaux après succès
	_emit_all_signals()
	
	return true

func get_remaining_in_hand() -> int:
	return remaining_in_hand

# --- Méthodes privées ---

func _validate_operation(op: Dictionary) -> bool:
	match op.type:
		"move", "swap", "restack":
			var source_slot = op.source_ctrl.inventory.get_slot(op.source_idx)
			var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
			return source_slot != null and target_slot != null
		"hand_restack":
			var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
			return target_slot != null
	return false

func _execute_operation(op: Dictionary) -> bool:
	match op.type:
		"move":
			return _execute_move(op)
		"swap":
			return _execute_swap(op)
		"restack":
			return _execute_restack(op)
		"hand_restack":
			return _execute_hand_restack(op)
	return false

func _execute_move(op: Dictionary) -> bool:
	var source_slot = op.source_ctrl.inventory.get_slot(op.source_idx)
	var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
	
	# Sauvegarder les données
	var item = source_slot.get_item()
	var quantity = source_slot.get_quantity()
	
	# Effectuer le déplacement
	source_slot.clear()
	var surplus = target_slot.add_item(item, quantity)
	
	# Gérer le surplus
	if surplus > 0:
		source_slot.add_item(item, surplus)
	
	return true

func _execute_swap(op: Dictionary) -> bool:
	var source_slot = op.source_ctrl.inventory.get_slot(op.source_idx)
	var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
	
	# Sauvegarder les données
	var source_item = source_slot.get_item()
	var source_qty = source_slot.get_quantity()
	var target_item = target_slot.get_item()
	var target_qty = target_slot.get_quantity()
	
	# Effectuer le swap
	source_slot.clear()
	target_slot.clear()
	source_slot.add_item(target_item, target_qty)
	target_slot.add_item(source_item, source_qty)
	
	return true

func _execute_restack(op: Dictionary) -> bool:
	var source_slot = op.source_ctrl.inventory.get_slot(op.source_idx)
	var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
	
	var source_qty = source_slot.get_quantity()
	var target_qty = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	
	var can_transfer = min(source_qty, target_max - target_qty)
	
	if can_transfer > 0:
		# Transférer
		source_slot.item_stack.quantity -= can_transfer
		target_slot.item_stack.quantity += can_transfer
		
		# Nettoyer si vide
		if source_slot.get_quantity() <= 0:
			source_slot.clear()
	
	return true

func _execute_hand_restack(op: Dictionary) -> bool:
	var hand_qty = op.hand_info.slot_data.get("quantity", 0)
	var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
	
	var target_qty = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	
	var can_transfer = min(hand_qty, target_max - target_qty)
	
	if can_transfer > 0:
		# Transférer vers la cible
		target_slot.item_stack.quantity += can_transfer
		
		# Calculer ce qui reste en main
		remaining_in_hand = hand_qty - can_transfer
		
		# Si on a un slot source réel, le mettre à jour
		if op.hand_info.has("slot_index") and op.hand_info.slot_index != -1:
			var source_ctrl = ServiceLocator.get_service("click_system").get_controller_for_container(
				op.hand_info.container_id
			)
			if source_ctrl:
				var source_slot = source_ctrl.inventory.get_slot(op.hand_info.slot_index)
				if source_slot:
					source_slot.item_stack.quantity -= can_transfer
					if source_slot.get_quantity() <= 0:
						source_slot.clear()
	
	return true

func _emit_all_signals():
	# Émettre tous les signaux nécessaires après le succès de la transaction
	var containers_to_refresh = {}
	
	for op in operations:
		# Collecter les containers à rafraîchir
		if op.has("source_ctrl"):
			containers_to_refresh[op.source_ctrl] = true
		if op.has("target_ctrl"):
			containers_to_refresh[op.target_ctrl] = true
		
		# Émettre les signaux des slots
		match op.type:
			"move", "swap", "restack":
				var source_slot = op.source_ctrl.inventory.get_slot(op.source_idx)
				var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
				if source_slot:
					source_slot.slot_changed.emit()
				if target_slot:
					target_slot.slot_changed.emit()
			"hand_restack":
				var target_slot = op.target_ctrl.inventory.get_slot(op.target_idx)
				if target_slot:
					target_slot.slot_changed.emit()
	
	# Émettre les signaux des inventaires
	for ctrl in containers_to_refresh:
		if ctrl and ctrl.inventory:
			ctrl.inventory.inventory_changed.emit()
