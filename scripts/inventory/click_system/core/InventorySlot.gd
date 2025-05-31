# scripts/inventory/core/InventorySlot.gd
class_name InventorySlot
extends RefCounted

# === SIGNAUX ===
signal slot_changed()

# === PROPRIÉTÉS ===
var index: int
var item_stack: ItemStack

func _init(slot_index: int = 0):
	index = slot_index
	item_stack = ItemStack.new()

# === GESTION DES ITEMS ===

func add_item(item: Item, quantity: int = 1) -> int:
	"""Ajoute un item au slot - retourne le surplus"""
	if not item or quantity <= 0:
		return quantity
	
	# Si le slot est vide, créer un nouveau stack
	if is_empty():
		item_stack = ItemStack.new(item, 0)
	
	# Vérifier si on peut ajouter l'item
	if not can_accept_item(item, quantity):
		return quantity
	
	var surplus = item_stack.add(quantity)
	
	if surplus < quantity:  # Quelque chose a été ajouté
		slot_changed.emit()
	
	return surplus

func remove_item(quantity: int = 1) -> ItemStack:
	"""Retire des items du slot"""
	if is_empty() or quantity <= 0:
		return ItemStack.new()
	
	var removed_quantity = item_stack.remove(quantity)
	
	# Créer un stack avec les items retirés
	var removed_stack = ItemStack.new(item_stack.item, removed_quantity)
	
	if removed_quantity > 0:
		slot_changed.emit()
	
	return removed_stack

func can_accept_item(item: Item, quantity: int = 1) -> bool:
	"""Vérifie si le slot peut accepter l'item"""
	if not item:
		return false
	
	# Slot vide peut accepter n'importe quel item
	if is_empty():
		return true
	
	# Même item et stackable
	if item_stack.can_stack_with(item):
		return item_stack.can_add(quantity)
	
	return false

# === ÉTAT DU SLOT ===

func is_empty() -> bool:
	"""Vérifie si le slot est vide"""
	return item_stack.is_empty()

func is_full() -> bool:
	"""Vérifie si le slot est plein"""
	return item_stack.is_full()

func get_item() -> Item:
	"""Récupère l'item du slot"""
	return item_stack.item

func get_quantity() -> int:
	"""Récupère la quantité d'items"""
	return item_stack.quantity

func get_max_stack_size() -> int:
	"""Récupère la taille max du stack"""
	if item_stack.item:
		return item_stack.item.max_stack_size
	return 1

# === UTILITAIRES ===

func clear():
	"""Vide le slot"""
	if not is_empty():
		item_stack.clear()
		slot_changed.emit()

func clone() -> InventorySlot:
	"""Crée une copie du slot"""
	var new_slot = InventorySlot.new(index)
	
	if not is_empty():
		new_slot.item_stack = ItemStack.new(item_stack.item, item_stack.quantity)
	
	return new_slot

# === DEBUG ===

func _to_string() -> String:
	if is_empty():
		return "Slot[%d]: vide" % index
	else:
		return "Slot[%d]: %s x%d" % [index, item_stack.item.name, item_stack.quantity]

func debug_info():
	"""Affiche les infos de debug du slot"""
	print("   Slot %d: %s" % [index, _to_string()])
