# scripts/inventory/data/InventorySlot.gd
class_name InventorySlot
extends RefCounted

signal content_changed(slot: InventorySlot)

var index: int = -1
var item_stack: ItemStack
var is_locked: bool = false

func _init(slot_index: int = -1):
	index = slot_index
	item_stack = ItemStack.new()

func is_empty() -> bool:
	return item_stack.is_empty()

func get_item() -> Item:
	return item_stack.item

func get_quantity() -> int:
	return item_stack.quantity

func can_accept_item(item: Item, quantity: int = 1) -> bool:
	if is_locked:
		return false
	
	if is_empty():
		return true
	
	return item_stack.can_stack_with(item) and item_stack.can_add(quantity)

func add_item(item: Item, quantity: int = 1) -> int:
	if not can_accept_item(item, quantity):
		return quantity
	
	if is_empty():
		item_stack.item = item
		item_stack.quantity = 0
	
	var surplus = item_stack.add(quantity)
	content_changed.emit(self)
	return surplus

func remove_item(quantity: int = 1) -> ItemStack:
	if is_empty():
		return ItemStack.new()
	
	var removed_item = item_stack.item
	var removed_quantity = item_stack.remove(quantity)
	
	content_changed.emit(self)
	return ItemStack.new(removed_item, removed_quantity)

func clear():
	item_stack.clear()
	content_changed.emit(self)
