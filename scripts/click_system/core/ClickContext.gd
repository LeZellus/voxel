# scripts/click_system/core/ClickContext.gd
class_name ClickContext
extends RefCounted

# === TYPES DE CLICS ===
enum ClickType {
	SIMPLE_LEFT_CLICK,      # Clic gauche simple
	SIMPLE_RIGHT_CLICK,     # Clic droit simple
	DOUBLE_LEFT_CLICK,      # Double-clic gauche
	SHIFT_LEFT_CLICK,       # Shift + clic gauche
	CTRL_LEFT_CLICK,        # Ctrl + clic gauche
	ALT_LEFT_CLICK,         # Alt + clic gauche
	MIDDLE_CLICK,           # Clic molette (pour plus tard)
	SHIFT_RIGHT_CLICK,      # Shift + clic droit
	CTRL_RIGHT_CLICK        # Ctrl + clic droit
}

# === CONTEXTE DU CLIC ===
var click_type: ClickType
var source_slot_index: int = -1
var source_container_id: String = ""
var target_slot_index: int = -1
var target_container_id: String = ""
var mouse_position: Vector2
var modifiers: Dictionary = {}

# === DONNÉES DES SLOTS ===
var source_slot_data: Dictionary = {}
var target_slot_data: Dictionary = {}

# === SYSTÈME ===
var timestamp: float
var is_cross_container: bool = false

func _init():
	timestamp = Time.get_time_dict_from_system()["unix"]

# === BUILDERS ===
static func create_slot_interaction(interaction_type: ClickType, slot_index: int, container_id: String, slot_data: Dictionary) -> ClickContext:
	var context = ClickContext.new()
	context.click_type = interaction_type
	context.source_slot_index = slot_index
	context.source_container_id = container_id
	context.source_slot_data = slot_data
	return context

static func create_slot_to_slot_interaction(
	interaction_type: ClickType,
	source_slot: int, source_container: String, source_data: Dictionary,
	target_slot: int, target_container: String, target_data: Dictionary
) -> ClickContext:
	var context = ClickContext.new()
	context.click_type = interaction_type
	context.source_slot_index = source_slot
	context.source_container_id = source_container
	context.source_slot_data = source_data
	context.target_slot_index = target_slot
	context.target_container_id = target_container
	context.target_slot_data = target_data
	context.is_cross_container = (source_container != target_container)
	return context

# === UTILITAIRES ===
func has_source_item() -> bool:
	return not source_slot_data.get("is_empty", true)

func has_target_item() -> bool:
	return not target_slot_data.get("is_empty", true)

func get_source_item_id() -> String:
	return source_slot_data.get("item_id", "")

func get_target_item_id() -> String:
	return target_slot_data.get("item_id", "")

func can_stack() -> bool:
	if not has_source_item() or not has_target_item():
		return false
	return get_source_item_id() == get_target_item_id()

func _to_string() -> String:
	return "ClickContext[%s]: %s[%d] -> %s[%d]" % [
		ClickType.keys()[click_type],
		source_container_id,
		source_slot_index,
		target_container_id if is_cross_container else "same",
		target_slot_index if is_cross_container else source_slot_index
	]
