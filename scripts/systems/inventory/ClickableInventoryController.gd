# scripts/click_system/core/ClickableInventoryController.gd
class_name ClickableInventoryController
extends RefCounted

var inventory: Inventory

func _init(inv: Inventory):
	inventory = inv

func get_slot_info(slot_index: int) -> Dictionary:
	"""Version click-system qui inclut item_type"""
	var slot = inventory.get_slot(slot_index)
	if not slot:
		return {"is_empty": true, "index": slot_index}
	
	var info = {
		"index": slot.index,
		"is_empty": slot.is_empty()
	}
	
	if not slot.is_empty():
		var item = slot.get_item()
		if item:
			info.merge({
				"item_id": item.id,
				"item_name": item.name,
				"item_type": item.item_type,  # ← INCLUS pour UseItemAction
				"quantity": slot.get_quantity(),
				"max_stack": item.max_stack_size,
				"icon": item.icon
			})
	
	return info

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Déplace un item entre deux slots"""
	var from_slot_obj = inventory.get_slot(from_slot)
	var to_slot_obj = inventory.get_slot(to_slot)
	
	if not from_slot_obj or not to_slot_obj or from_slot_obj.is_empty():
		return false
	
	if from_slot == to_slot:
		return false
	
	var item = from_slot_obj.get_item()
	var quantity = from_slot_obj.get_quantity()
	
	# Slot vide : déplacer tout
	if to_slot_obj.is_empty():
		var removed = from_slot_obj.remove_item(quantity)
		to_slot_obj.add_item(item, removed.quantity)
		return true
	
	# Même item : stack
	elif to_slot_obj.can_accept_item(item, quantity):
		var removed = from_slot_obj.remove_item(quantity)
		var surplus = to_slot_obj.add_item(item, removed.quantity)
		if surplus > 0:
			from_slot_obj.add_item(item, surplus)
		return true
	
	# Différent : swap
	else:
		var temp_item = to_slot_obj.get_item()
		var temp_qty = to_slot_obj.get_quantity()
		
		to_slot_obj.clear()
		from_slot_obj.clear()
		
		to_slot_obj.add_item(item, quantity)
		from_slot_obj.add_item(temp_item, temp_qty)
		return true

func remove_item(item_id: String, quantity: int = 1) -> int:
	"""Retire un item de l'inventaire"""
	return inventory.remove_item(item_id, quantity)
