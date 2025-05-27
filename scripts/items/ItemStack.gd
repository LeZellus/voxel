# ItemStack.gd - Représente une pile d'items
class_name ItemStack
extends Resource

@export var item: Item
@export var quantity: int = 0

func _init(p_item: Item = null, p_quantity: int = 0):
	item = p_item
	quantity = p_quantity

# Vérifie si la pile est vide
func is_empty() -> bool:
	return item == null or quantity <= 0

# Vérifie si on peut ajouter des items à cette pile
func can_add_item(other_item: Item, amount: int = 1) -> bool:
	if is_empty():
		return true
	if item.id != other_item.id:
		return false
	if not item.is_stackable:
		return false
	return quantity + amount <= item.max_stack_size

# Ajoute des items à la pile
func add_item(other_item: Item, amount: int = 1) -> int:
	if is_empty():
		item = other_item
		quantity = amount
		return 0
	
	if not can_add_item(other_item, amount):
		return amount
	
	var space_available = item.max_stack_size - quantity
	var amount_to_add = min(amount, space_available)
	quantity += amount_to_add
	return amount - amount_to_add

# Retire des items de la pile
func remove_item(amount: int = 1) -> int:
	var amount_to_remove = min(amount, quantity)
	quantity -= amount_to_remove
	
	if quantity <= 0:
		item = null
		quantity = 0
	
	return amount_to_remove
