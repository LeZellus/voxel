# Inventory.gd - Gère la logique de l'inventaire
class_name Inventory
extends Node

signal inventory_changed
signal slot_changed(slot_index: int)

@export var size: int = 36  # Taille de l'inventaire (comme Minecraft)
var slots: Array[ItemStack] = []

func _ready():
	# Initialise tous les slots vides
	slots.resize(size)
	for i in range(size):
		slots[i] = ItemStack.new()

# Ajoute un item à l'inventaire
func add_item(item: Item, quantity: int = 1) -> int:
	var remaining = quantity
	
	# D'abord, essaye d'ajouter aux piles existantes du même type
	for i in range(size):
		if slots[i].item != null and slots[i].item.id == item.id:
			remaining = slots[i].add_item(item, remaining)
			if remaining == 0:
				slot_changed.emit(i)
				inventory_changed.emit()
				return 0
			slot_changed.emit(i)
	
	# Ensuite, utilise les slots vides
	for i in range(size):
		if slots[i].is_empty():
			remaining = slots[i].add_item(item, remaining)
			if remaining == 0:
				slot_changed.emit(i)
				inventory_changed.emit()
				return 0
			slot_changed.emit(i)
	
	inventory_changed.emit()
	return remaining

# Obtient un slot spécifique
func get_slot(index: int) -> ItemStack:
	if index >= 0 and index < size:
		return slots[index]
	return null

# Définit un slot spécifique
func set_slot(index: int, item_stack: ItemStack):
	if index >= 0 and index < size:
		slots[index] = item_stack if item_stack != null else ItemStack.new()
		slot_changed.emit(index)
		inventory_changed.emit()

# Retire un item de l'inventaire
func remove_item(item_id: String, quantity: int = 1) -> int:
	var removed = 0
	var remaining = quantity
	
	for i in range(size):
		if slots[i].item != null and slots[i].item.id == item_id:
			var removed_from_slot = slots[i].remove_item(remaining)
			removed += removed_from_slot
			remaining -= removed_from_slot
			slot_changed.emit(i)
			
			if remaining <= 0:
				break
	
	if removed > 0:
		inventory_changed.emit()
	
	return removed

# Vérifie si l'inventaire contient un item
func has_item(item_id: String, quantity: int = 1) -> bool:
	var count = 0
	for slot in slots:
		if slot.item != null and slot.item.id == item_id:
			count += slot.quantity
			if count >= quantity:
				return true
	return false

# Compte le nombre total d'un item dans l'inventaire
func count_item(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.item != null and slot.item.id == item_id:
			count += slot.quantity
	return count

# Trouve le premier slot vide
func find_empty_slot() -> int:
	for i in range(size):
		if slots[i].is_empty():
			return i
	return -1

# Vérifie si l'inventaire est plein
func is_full() -> bool:
	return find_empty_slot() == -1
