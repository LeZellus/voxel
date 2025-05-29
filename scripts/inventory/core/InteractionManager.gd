# scripts/inventory/core/InteractionManager.gd
class_name InteractionManager
extends RefCounted

signal interaction_started(interaction_type: String)
signal interaction_completed(interaction_type: String, success: bool)

var controller: InventoryController
var current_interaction: Dictionary = {}

enum InteractionType {
	NONE,
	DRAGGING,
	SPLITTING,
	QUICK_MOVING,
	CONTEXT_MENU
}

func _init(inventory_controller: InventoryController):
	controller = inventory_controller

# === GESTION DU DRAG & DROP ===
func start_drag(slot_index: int) -> bool:
	if current_interaction.has("type"):
		return false  # Une interaction est déjà en cours
	
	var slot_info = controller.get_slot_info(slot_index)
	if slot_info.is_empty():
		return false
	
	current_interaction = {
		"type": InteractionType.DRAGGING,
		"source_slot": slot_index,
		"item_id": slot_info.item_id,
		"quantity": slot_info.quantity
	}
	
	interaction_started.emit("drag")
	return true

func complete_drag(target_slot: int) -> bool:
	if not _is_interaction_type(InteractionType.DRAGGING):
		return false
	
	var source_slot = current_interaction.source_slot
	var success = controller.move_item(source_slot, target_slot)
	
	_end_interaction()
	interaction_completed.emit("drag", success)
	return success

func cancel_drag():
	if _is_interaction_type(InteractionType.DRAGGING):
		_end_interaction()
		interaction_completed.emit("drag", false)

# === GESTION DU SPLIT ===
func start_split(slot_index: int, split_amount: int) -> bool:
	var slot_info = controller.get_slot_info(slot_index)
	if slot_info.is_empty() or slot_info.quantity <= 1:
		return false
	
	current_interaction = {
		"type": InteractionType.SPLITTING,
		"source_slot": slot_index,
		"split_amount": min(split_amount, slot_info.quantity - 1)
	}
	
	interaction_started.emit("split")
	return true

func complete_split(target_slot: int) -> bool:
	if not _is_interaction_type(InteractionType.SPLITTING):
		return false
	
	var source_slot = current_interaction.source_slot
	var amount = current_interaction.split_amount
	var success = controller.split_stack(source_slot, amount)
	
	_end_interaction()
	interaction_completed.emit("split", success)
	return success

# === INTERACTIONS AVEC MODIFICATEURS ===
func handle_click(slot_index: int, modifiers: Dictionary = {}) -> bool:
	var shift_pressed = modifiers.get("shift", false)
	var ctrl_pressed = modifiers.get("ctrl", false)
	
	if shift_pressed:
		return handle_quick_move(slot_index)
	elif ctrl_pressed:
		return handle_split_request(slot_index)
	else:
		return handle_normal_click(slot_index)

func handle_quick_move(slot_index: int) -> bool:
	current_interaction = {
		"type": InteractionType.QUICK_MOVING,
		"source_slot": slot_index
	}
	
	var success = controller.quick_move_item(slot_index)
	_end_interaction()
	interaction_completed.emit("quick_move", success)
	return success

func handle_split_request(slot_index: int) -> bool:
	var slot_info = controller.get_slot_info(slot_index)
	if slot_info.is_empty() or slot_info.quantity <= 1:
		return false
	
	# Par défaut, split en deux
	var split_amount = slot_info.quantity / 2
	return start_split(slot_index, split_amount)

func handle_normal_click(slot_index: int) -> bool:
	# Si on est en train de drag, compléter le drag
	if _is_interaction_type(InteractionType.DRAGGING):
		return complete_drag(slot_index)
	
	# Sinon, commencer un drag
	return start_drag(slot_index)

# === GESTION D'ÉTAT ===
func is_interacting() -> bool:
	return current_interaction.has("type")

func get_current_interaction_type() -> InteractionType:
	return current_interaction.get("type", InteractionType.NONE)

func get_interaction_info() -> Dictionary:
	return current_interaction.duplicate()

func _is_interaction_type(type: InteractionType) -> bool:
	return current_interaction.get("type") == type

func _end_interaction():
	current_interaction.clear()

# === DEBUG ===
func get_interaction_state() -> String:
	if not is_interacting():
		return "Aucune interaction"
	
	var type = get_current_interaction_type()
	match type:
		InteractionType.DRAGGING:
			return "Drag depuis slot %d" % current_interaction.source_slot
		InteractionType.SPLITTING:
			return "Split slot %d (quantité: %d)" % [current_interaction.source_slot, current_interaction.split_amount]
		InteractionType.QUICK_MOVING:
			return "Quick move slot %d" % current_interaction.source_slot
		_:
			return "Interaction inconnue"
