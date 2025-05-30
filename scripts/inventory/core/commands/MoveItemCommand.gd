# scripts/inventory/core/commands/MoveItemCommand.gd
class_name MoveItemCommand
extends Command

var inventory: Inventory
var from_slot_index: int
var to_slot_index: int
var moved_stack: ItemStack
var original_target_stack: ItemStack

func _init(inv: Inventory, from_index: int, to_index: int):
	inventory = inv
	from_slot_index = from_index
	to_slot_index = to_index

func can_execute() -> bool:
	if not inventory:
		return false
	
	if from_slot_index < 0 or from_slot_index >= Constants.INVENTORY_SIZE:
		return false
	
	if to_slot_index < 0 or to_slot_index >= Constants.INVENTORY_SIZE:
		return false
	
	if from_slot_index == to_slot_index:
		return false
	
	var from_slot = inventory.get_slot(from_slot_index)
	return not from_slot.is_empty()

func execute() -> bool:
	if not can_execute():
		return false
	
	var from_slot = inventory.get_slot(from_slot_index)
	var to_slot = inventory.get_slot(to_slot_index)
	
	# Sauvegarde pour l'undo
	moved_stack = ItemStack.new(from_slot.get_item(), from_slot.get_quantity())
	original_target_stack = ItemStack.new(to_slot.get_item(), to_slot.get_quantity()) if not to_slot.is_empty() else null
	
	# Cas 1: Slot de destination vide
	if to_slot.is_empty():
		to_slot.add_item(moved_stack.item, moved_stack.quantity)
		from_slot.clear()
		return true
	
	# Cas 2: Items identiques et stackables
	if to_slot.can_accept_item(moved_stack.item, moved_stack.quantity):
		var surplus = to_slot.add_item(moved_stack.item, moved_stack.quantity)
		from_slot.clear()
		
		# S'il y a un surplus, le remettre dans le slot source
		if surplus > 0:
			from_slot.add_item(moved_stack.item, surplus)
		return true
	
	# Cas 3: Échange de position (swap)
	var temp_item = to_slot.get_item()
	var temp_quantity = to_slot.get_quantity()
	
	to_slot.clear()
	to_slot.add_item(moved_stack.item, moved_stack.quantity)
	
	from_slot.clear()
	from_slot.add_item(temp_item, temp_quantity)
	
	return true

func undo() -> bool:
	if not inventory or not moved_stack:
		return false
	
	var from_slot = inventory.get_slot(from_slot_index)
	var to_slot = inventory.get_slot(to_slot_index)
	
	# Restaure l'état original
	from_slot.clear()
	from_slot.add_item(moved_stack.item, moved_stack.quantity)
	
	to_slot.clear()
	if original_target_stack:
		to_slot.add_item(original_target_stack.item, original_target_stack.quantity)
	
	return true

func get_description() -> String:
	return "Move item from slot %d to slot %d" % [from_slot_index, to_slot_index]
