class_name Hotbar
extends BaseContainer

const HOTBAR_SIZE = 9
var selected_slot: int = 0

signal slot_selected(slot_index: int)
signal item_used(slot_index: int, item: Item)

func _init():
	super("hotbar", HOTBAR_SIZE, "Barre d'outils")

func select_slot(slot_index: int):
	if slot_index >= 0 and slot_index < HOTBAR_SIZE:
		selected_slot = slot_index
		slot_selected.emit(slot_index)

func get_selected_item() -> Item:
	var slot = inventory.get_slot(selected_slot)
	return slot.get_item() if not slot.is_empty() else null

func use_selected_item():
	var slot = inventory.get_slot(selected_slot)
	if not slot.is_empty():
		var item = slot.get_item()
		var removed = slot.remove_item(1)
		if removed.quantity > 0:
			item_used.emit(selected_slot, item)
