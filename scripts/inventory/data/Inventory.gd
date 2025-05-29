# scripts/inventory/data/Inventory.gd
class_name Inventory
extends RefCounted

signal inventory_changed()
signal item_added(item: Item, quantity: int, slot_index: int)
signal item_removed(item: Item, quantity: int, slot_index: int)
signal slot_changed(slot_index: int)

var slots: Array[InventorySlot] = []
var size: int
var name: String = "Inventory"

func _init(inventory_size: int = 20, inventory_name: String = "Main Inventory"):
	size = inventory_size
	name = inventory_name
	_initialize_slots()

func _initialize_slots():
	slots.clear()
	for i in size:
		var slot = InventorySlot.new(i)
		slot.content_changed.connect(_on_slot_changed)
		slots.append(slot)

# === ACCESSEURS DE BASE ===
func get_size() -> int:
	return size

func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= size:
		push_error("Index de slot invalide: " + str(index))
		return null
	return slots[index]

func is_slot_valid(index: int) -> bool:
	return index >= 0 and index < size

# === AJOUT D'ITEMS ===
func add_item(item: Item, quantity: int = 1) -> int:
	if not item or quantity <= 0:
		return quantity
	
	var remaining = quantity
	
	# Étape 1: Essayer de stack sur les slots existants
	for slot in slots:
		if not slot.is_empty() and slot.can_accept_item(item, remaining):
			var added = remaining - slot.add_item(item, remaining)
			remaining -= added
			if added > 0:
				item_added.emit(item, added, slot.index)
			
			if remaining <= 0:
				break
	
	# Étape 2: Utiliser les slots vides
	if remaining > 0:
		for slot in slots:
			if slot.is_empty():
				var to_add = min(remaining, item.max_stack_size)
				var surplus = slot.add_item(item, to_add)
				var actually_added = to_add - surplus
				remaining -= actually_added
				
				if actually_added > 0:
					item_added.emit(item, actually_added, slot.index)
				
				if remaining <= 0:
					break
	
	return remaining

# === RETRAIT D'ITEMS ===
func remove_item(item_id: String, quantity: int = 1) -> int:
	if quantity <= 0:
		return 0
	
	var remaining = quantity
	
	for slot in slots:
		if not slot.is_empty() and slot.get_item().id == item_id:
			var available = slot.get_quantity()
			var to_remove = min(remaining, available)
			
			var removed_stack = slot.remove_item(to_remove)
			var actually_removed = removed_stack.quantity
			remaining -= actually_removed
			
			if actually_removed > 0:
				item_removed.emit(removed_stack.item, actually_removed, slot.index)
			
			if remaining <= 0:
				break
	
	return quantity - remaining

# === RECHERCHE ET VERIFICATION ===
func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity

func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in slots:
		if not slot.is_empty() and slot.get_item().id == item_id:
			total += slot.get_quantity()
	return total

func find_item_slot(item_id: String) -> int:
	for slot in slots:
		if not slot.is_empty() and slot.get_item().id == item_id:
			return slot.index
	return -1

func find_empty_slot() -> int:
	for slot in slots:
		if slot.is_empty():
			return slot.index
	return -1

func find_stackable_slot(item: Item) -> int:
	for slot in slots:
		if not slot.is_empty() and slot.can_accept_item(item, 1):
			return slot.index
	return -1

# === UTILITÉS ===
func is_full() -> bool:
	for slot in slots:
		if slot.is_empty():
			return false
	return true

func is_empty() -> bool:
	for slot in slots:
		if not slot.is_empty():
			return false
	return true

func get_used_slots_count() -> int:
	var count = 0
	for slot in slots:
		if not slot.is_empty():
			count += 1
	return count

func get_free_slots_count() -> int:
	return size - get_used_slots_count()

# === TRANSFERT ENTRE INVENTAIRES ===
func transfer_to(other_inventory: Inventory, item_id: String, quantity: int = 1) -> int:
	var removed = remove_item(item_id, quantity)
	if removed > 0:
		var surplus = other_inventory.add_item(_find_item_by_id(item_id), removed)
		if surplus > 0:
			# Remettre le surplus dans l'inventaire source
			add_item(_find_item_by_id(item_id), surplus)
		return removed - surplus
	return 0

func _find_item_by_id(item_id: String) -> Item:
	for slot in slots:
		if not slot.is_empty() and slot.get_item().id == item_id:
			return slot.get_item()
	return null

# === DEBUG ET AFFICHAGE ===
func get_contents_summary() -> String:
	var summary = "=== %s (%d/%d slots) ===\n" % [name, get_used_slots_count(), size]
	for slot in slots:
		if not slot.is_empty():
			summary += "Slot %d: %s x%d\n" % [slot.index, slot.get_item().name, slot.get_quantity()]
	return summary

func print_contents():
	print(get_contents_summary())

# === GESTION DES SIGNAUX ===
func _on_slot_changed(slot: InventorySlot):
	slot_changed.emit(slot.index)
	inventory_changed.emit()
