# scripts/inventory/core/InventoryController.gd
class_name InventoryController
extends RefCounted

signal action_performed(action_type: String, result: bool)

var inventory: Inventory
var command_system: CommandSystem
var interaction_manager: InteractionManager

func _init(inventory_data: Inventory):
	inventory = inventory_data
	command_system = CommandSystem.new()
	interaction_manager = InteractionManager.new(self)
	_connect_signals()

func _connect_signals():
	command_system.command_executed.connect(_on_command_executed)
	command_system.command_undone.connect(_on_command_undone)
	interaction_manager.interaction_completed.connect(_on_interaction_completed)

# === ACTIONS PRINCIPALES ===
func move_item(from_slot: int, to_slot: int) -> bool:
	var command = MoveItemCommand.new(inventory, from_slot, to_slot)
	var result = command_system.execute(command)
	action_performed.emit("move_item", result)
	return result

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	var surplus = inventory.add_item(item, quantity)
	var added = quantity - surplus
	if added > 0:
		action_performed.emit("add_item", true)
	return surplus

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	var removed = inventory.remove_item(item_id, quantity)
	if removed > 0:
		action_performed.emit("remove_item", true)
	return removed

# === COMMANDES AVANCÉES ===
func quick_move_item(slot_index: int) -> bool:
	# TODO: Implémenter QuickMoveCommand
	print("Quick move pas encore implémenté")
	return false

func split_stack(slot_index: int, split_amount: int) -> bool:
	# TODO: Implémenter SplitStackCommand  
	print("Split stack pas encore implémenté")
	return false

func stack_all_items(item_id: String) -> bool:
	# TODO: Implémenter StackAllCommand
	print("Stack all pas encore implémenté")
	return false

# === UNDO/REDO ===
func undo_last_action() -> bool:
	var result = command_system.undo()
	if result:
		action_performed.emit("undo", true)
	return result

func redo_last_action() -> bool:
	var result = command_system.redo()
	if result:
		action_performed.emit("redo", true)
	return result

func can_undo() -> bool:
	return command_system.can_undo()

func can_redo() -> bool:
	return command_system.can_redo()

# === QUERIES POUR L'UI ===
func get_slot_info(slot_index: int) -> Dictionary:
	var slot = inventory.get_slot(slot_index)
	if not slot:
		return {}
	
	var info = {
		"index": slot.index,
		"is_empty": slot.is_empty(),
		"is_locked": slot.is_locked
	}
	
	if not slot.is_empty():
		var item = slot.get_item()
		info.merge({
			"item_id": item.id,
			"item_name": item.name,
			"quantity": slot.get_quantity(),
			"max_stack": item.max_stack_size,
			"icon": item.icon
		})
	
	return info

func get_inventory_summary() -> Dictionary:
	return {
		"name": inventory.name,
		"size": inventory.get_size(),
		"used_slots": inventory.get_used_slots_count(),
		"free_slots": inventory.get_free_slots_count(),
		"is_full": inventory.is_full(),
		"is_empty": inventory.is_empty()
	}

# === VALIDATION ===
func can_move_item(from_slot: int, to_slot: int) -> bool:
	var command = MoveItemCommand.new(inventory, from_slot, to_slot)
	return command.can_execute()

func can_add_item(item: Item, quantity: int = 1) -> bool:
	if not item:
		return false
	return inventory.get_free_slots_count() > 0 or inventory.find_stackable_slot(item) >= 0

# === GESTION DES SIGNAUX ===
func _on_command_executed(command: Command):
	print("🎮 Controller: ", command.get_description(), " exécutée")

func _on_command_undone(command: Command):
	print("🎮 Controller: ", command.get_description(), " annulée")

func _on_interaction_completed(interaction_type: String, success: bool):
	print("🎮 Interaction ", interaction_type, " terminée:", success)
