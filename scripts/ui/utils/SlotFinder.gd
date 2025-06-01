# scripts/ui/utils/SlotFinder.gd
class_name SlotFinder
extends RefCounted

static func find_slot_ui_for_context(context: ClickContext, registered_uis: Dictionary) -> ClickableSlotUI:
	"""Trouve le ClickableSlotUI correspondant au contexte"""
	var ui = registered_uis.get(context.source_container_id)
	if not ui:
		return null
	
	return find_slot_in_container(ui, context.source_slot_index)

static func find_slot_in_container(ui: Control, slot_index: int) -> ClickableSlotUI:
	"""Trouve un slot spécifique dans une UI container"""
	var slots = find_all_slots_in_ui(ui)
	for slot in slots:
		if slot.get_slot_index() == slot_index:
			return slot
	return null

static func find_all_slots_in_ui(ui: Control) -> Array[ClickableSlotUI]:
	"""Trouve tous les ClickableSlotUI dans une UI"""
	var slots: Array[ClickableSlotUI] = []
	_find_slots_recursive(ui, slots)
	return slots

static func _find_slots_recursive(node: Node, slots: Array[ClickableSlotUI]):
	"""Recherche récursive de ClickableSlotUI"""
	if node is ClickableSlotUI:
		slots.append(node as ClickableSlotUI)
	
	for child in node.get_children():
		_find_slots_recursive(child, slots)
