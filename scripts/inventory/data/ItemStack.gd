# scripts/inventory/data/ItemStack.gd
class_name ItemStack
extends RefCounted

var item: Item
var quantity: int = 0

func _init(item_data: Item = null, qty: int = 1):
	item = item_data
	quantity = qty if item_data else 0

func is_empty() -> bool:
	return item == null or quantity <= 0

func is_full() -> bool:
	return item != null and quantity >= item.max_stack_size

func can_add(amount: int) -> bool:
	if not item:
		return true
	return quantity + amount <= item.max_stack_size

func add(amount: int) -> int:
	if not item:
		return amount
	
	var can_add_amount = min(amount, item.max_stack_size - quantity)
	quantity += can_add_amount
	return amount - can_add_amount  # Retourne le surplus

func remove(amount: int) -> int:
	var removed = min(amount, quantity)
	quantity -= removed
	
	if quantity <= 0:
		clear()
	
	return removed

func clear():
	item = null
	quantity = 0

func can_stack_with(other_item: Item) -> bool:
	if not item or not other_item:
		return false
	return item.id == other_item.id and item.is_stackable
