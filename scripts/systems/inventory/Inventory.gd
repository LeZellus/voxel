# scripts/inventory/core/Inventory.gd
class_name Inventory
extends RefCounted

# === SIGNAUX ===
signal inventory_changed()
signal slot_changed(slot_index: int)
signal item_added(item: Item, quantity: int, slot_index: int)
signal item_removed(item: Item, quantity: int, slot_index: int)

# === PROPRIÉTÉS ===
var name: String
var size: int
var slots: Array[InventorySlot] = []

func _init(inventory_size: int = 45, inventory_name: String = "Inventory"):
	size = inventory_size
	name = inventory_name
	_create_slots()

# === CRÉATION DES SLOTS ===

func _create_slots():
	"""Crée tous les slots de l'inventaire"""
	slots.clear()
	slots.resize(size)
	
	for i in range(size):
		var slot = InventorySlot.new(i)
		slot.slot_changed.connect(_on_slot_changed.bind(i))
		slots[i] = slot
	
	print("✅ Inventaire '%s' créé: %d slots" % [name, size])

func _on_slot_changed(slot_index: int):
	"""Callback quand un slot change"""
	slot_changed.emit(slot_index)
	inventory_changed.emit()

# === GESTION DES ITEMS ===

func add_item(item: Item, quantity: int = 1) -> int:
	"""Ajoute un item à l'inventaire - retourne le surplus"""
	if not item or quantity <= 0:
		return quantity
	
	var remaining = quantity
	
	# Étape 1: Essayer de stacker avec les items existants
	if item.is_stackable:
		for slot in slots:
			if slot.can_accept_item(item, remaining):
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
				var added = to_add - surplus
				
				remaining -= added
				
				if added > 0:
					item_added.emit(item, added, slot.index)
				
				if remaining <= 0:
					break
	
	return remaining

func remove_item(item_id: String, quantity: int = 1) -> int:
	"""Retire un item de l'inventaire - retourne la quantité retirée"""
	if quantity <= 0:
		return 0
	
	var removed_total = 0
	var remaining = quantity
	
	# Parcourir tous les slots
	for slot in slots:
		if slot.is_empty():
			continue
		
		var slot_item = slot.get_item()
		if slot_item and slot_item.id == item_id:
			var to_remove = min(remaining, slot.get_quantity())
			var removed_stack = slot.remove_item(to_remove)
			var removed = removed_stack.quantity
			
			removed_total += removed
			remaining -= removed
			
			if removed > 0:
				item_removed.emit(slot_item, removed, slot.index)
			
			if remaining <= 0:
				break
	
	return removed_total

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Vérifie si l'inventaire contient suffisamment d'items"""
	return get_item_count(item_id) >= quantity

func get_item_count(item_id: String) -> int:
	"""Compte le nombre total d'items d'un type"""
	var total = 0
	
	for slot in slots:
		if not slot.is_empty():
			var item = slot.get_item()
			if item and item.id == item_id:
				total += slot.get_quantity()
	
	return total

# === GESTION DES SLOTS ===

func get_slot(index: int) -> InventorySlot:
	"""Récupère un slot par son index"""
	if index < 0 or index >= size:
		return null
	return slots[index]

func get_first_empty_slot() -> InventorySlot:
	"""Trouve le premier slot vide"""
	for slot in slots:
		if slot.is_empty():
			return slot
	return null

func get_slots_with_item(item_id: String) -> Array[InventorySlot]:
	"""Trouve tous les slots contenant un item spécifique"""
	var result: Array[InventorySlot] = []
	
	for slot in slots:
		if not slot.is_empty():
			var item = slot.get_item()
			if item and item.id == item_id:
				result.append(slot)
	
	return result

# === INFORMATIONS ===

func get_used_slots_count() -> int:
	"""Compte le nombre de slots utilisés"""
	var count = 0
	for slot in slots:
		if not slot.is_empty():
			count += 1
	return count

func get_empty_slots_count() -> int:
	"""Compte le nombre de slots vides"""
	return size - get_used_slots_count()

func is_full() -> bool:
	"""Vérifie si l'inventaire est plein"""
	return get_empty_slots_count() == 0

func is_empty() -> bool:
	"""Vérifie si l'inventaire est vide"""
	return get_used_slots_count() == 0

# === UTILITAIRES ===

func clear():
	"""Vide complètement l'inventaire"""
	for slot in slots:
		slot.clear()
	
	inventory_changed.emit()

func get_all_items() -> Array[Dictionary]:
	"""Retourne tous les items avec leurs quantités"""
	var items: Array[Dictionary] = []
	
	for slot in slots:
		if not slot.is_empty():
			items.append({
				"item": slot.get_item(),
				"quantity": slot.get_quantity(),
				"slot_index": slot.index
			})
	
	return items

# === DEBUG ===

func debug_info():
	"""Affiche les informations de debug"""
	print("\n📦 Inventaire '%s':" % name)
	print("   - Taille: %d slots" % size)
	print("   - Utilisés: %d/%d" % [get_used_slots_count(), size])
	print("   - Vides: %d" % get_empty_slots_count())
	
	print("   - Contenu:")
	for slot in slots:
		if not slot.is_empty():
			print("     %s" % slot._to_string())
