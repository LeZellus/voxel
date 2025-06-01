# scripts/systems/inventory/ClickContext.gd - EXTENSION DE VOTRE VERSION EXISTANTE
class_name ClickContext
extends RefCounted

# === TYPES DE CLICS ÉTENDUS ===
enum ClickType {
	# Vos types existants
	SIMPLE_LEFT_CLICK,
	SIMPLE_RIGHT_CLICK,
	DOUBLE_LEFT_CLICK,
	SHIFT_LEFT_CLICK,
	CTRL_LEFT_CLICK,
	ALT_LEFT_CLICK,
	MIDDLE_CLICK,
	SHIFT_RIGHT_CLICK,
	CTRL_RIGHT_CLICK,
	# NOUVEAUX TYPES
	LEFT_DRAG_START,
	LEFT_DRAG_CONTINUE,
	LEFT_DRAG_END,
	RIGHT_HOLD_START,
	RIGHT_HOLD_CONTINUE,
	RIGHT_HOLD_END
}

# === ALIAS POUR COMPATIBILITÉ ===
enum ActionType {
	SIMPLE_LEFT_CLICK = ClickType.SIMPLE_LEFT_CLICK,
	SIMPLE_RIGHT_CLICK = ClickType.SIMPLE_RIGHT_CLICK,
	MIDDLE_CLICK = ClickType.MIDDLE_CLICK,
	DOUBLE_LEFT_CLICK = ClickType.DOUBLE_LEFT_CLICK,
	SHIFT_LEFT_CLICK = ClickType.SHIFT_LEFT_CLICK,
	LEFT_DRAG_START = ClickType.LEFT_DRAG_START,
	LEFT_DRAG_CONTINUE = ClickType.LEFT_DRAG_CONTINUE,
	LEFT_DRAG_END = ClickType.LEFT_DRAG_END,
	RIGHT_HOLD_START = ClickType.RIGHT_HOLD_START,
	RIGHT_HOLD_CONTINUE = ClickType.RIGHT_HOLD_CONTINUE,
	RIGHT_HOLD_END = ClickType.RIGHT_HOLD_END
}

# === CONTEXTE DU CLIC (existant) ===
var click_type: ClickType
var source_slot_index: int = -1
var source_container_id: String = ""
var target_slot_index: int = -1
var target_container_id: String = ""
var mouse_position: Vector2

# === NOUVELLES PROPRIÉTÉS ===
var modifiers: Dictionary = {"shift": false, "ctrl": false, "alt": false}
var drag_data: Dictionary = {}
var hold_data: Dictionary = {}
var sequence_id: String = ""

# === DONNÉES DES SLOTS (existant) ===
var source_slot_data: Dictionary = {}
var target_slot_data: Dictionary = {}

# === SYSTÈME (existant) ===
var timestamp: float
var is_cross_container: bool = false

func _init():
	timestamp = Time.get_unix_time_from_system()
	sequence_id = _generate_sequence_id()

# === BUILDERS EXISTANTS (gardés pour compatibilité) ===
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

# === NOUVEAU BUILDER AVANCÉ ===
static func create_advanced_interaction(
	action: ClickType,
	slot_index: int,
	container_id: String,
	slot_data: Dictionary,
	modifiers_state: Dictionary = {},
	extra_data: Dictionary = {}
) -> ClickContext:
	
	var context = ClickContext.new()
	context.click_type = action
	context.source_slot_index = slot_index
	context.source_container_id = container_id
	context.source_slot_data = slot_data
	context.modifiers = modifiers_state
	
	# Traiter les données supplémentaires selon le type
	match action:
		ClickType.LEFT_DRAG_START, ClickType.LEFT_DRAG_CONTINUE, ClickType.LEFT_DRAG_END:
			context.drag_data = extra_data
		ClickType.RIGHT_HOLD_START, ClickType.RIGHT_HOLD_CONTINUE, ClickType.RIGHT_HOLD_END:
			context.hold_data = extra_data
	
	return context

# === UTILITAIRES EXISTANTS (gardés) ===
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

# === NOUVELLES VÉRIFICATIONS ===
func is_drag_action() -> bool:
	return click_type in [ClickType.LEFT_DRAG_START, ClickType.LEFT_DRAG_CONTINUE, ClickType.LEFT_DRAG_END]

func is_hold_action() -> bool:
	return click_type in [ClickType.RIGHT_HOLD_START, ClickType.RIGHT_HOLD_CONTINUE, ClickType.RIGHT_HOLD_END]

func is_modified_action() -> bool:
	return modifiers.shift or modifiers.ctrl or modifiers.alt

func is_sequence_start() -> bool:
	return click_type in [ClickType.LEFT_DRAG_START, ClickType.RIGHT_HOLD_START]

func is_sequence_end() -> bool:
	return click_type in [ClickType.LEFT_DRAG_END, ClickType.RIGHT_HOLD_END]

func has_shift() -> bool:
	return modifiers.get("shift", false)

func has_ctrl() -> bool:
	return modifiers.get("ctrl", false)

func has_alt() -> bool:
	return modifiers.get("alt", false)

# === DONNÉES DE SÉQUENCE ===
func get_drag_distance() -> float:
	return drag_data.get("distance", 0.0)

func get_drag_start_pos() -> Vector2:
	return drag_data.get("start_position", Vector2.ZERO)

func get_hold_duration() -> float:
	return hold_data.get("duration", 0.0)

func get_slots_visited() -> Array:
	"""Pour les actions de distribution (drag/hold sur plusieurs slots)"""
	if is_drag_action():
		return drag_data.get("slots_visited", [])
	elif is_hold_action():
		return hold_data.get("slots_visited", [])
	return []

func add_visited_slot(slot_index: int):
	"""Ajoute un slot à la liste des slots visités"""
	if is_drag_action():
		var slots = drag_data.get("slots_visited", [])
		if slot_index not in slots:
			slots.append(slot_index)
			drag_data["slots_visited"] = slots
	elif is_hold_action():
		var slots = hold_data.get("slots_visited", [])
		if slot_index not in slots:
			slots.append(slot_index)
			hold_data["slots_visited"] = slots

# === UTILITAIRES ===
func _generate_sequence_id() -> String:
	return "seq_%d_%d" % [Time.get_unix_time_from_system() * 1000, randi() % 1000]

func clone_for_sequence() -> ClickContext:
	"""Crée une copie pour la même séquence"""
	var clone = ClickContext.new()
	clone.sequence_id = sequence_id  # Même ID de séquence
	clone.source_container_id = source_container_id
	clone.modifiers = modifiers.duplicate()
	clone.drag_data = drag_data.duplicate()
	clone.hold_data = hold_data.duplicate()
	return clone

func update_drag_distance(current_pos: Vector2):
	"""Met à jour la distance de drag"""
	var start_pos = get_drag_start_pos()
	if start_pos != Vector2.ZERO:
		drag_data["distance"] = start_pos.distance_to(current_pos)
		drag_data["current_position"] = current_pos

func update_hold_duration():
	"""Met à jour la durée du hold"""
	var start_time = hold_data.get("start_time", 0.0)
	if start_time > 0:
		hold_data["duration"] = Time.get_unix_time_from_system() - start_time

# === DEBUG ===
func _to_string() -> String:
	var action_name = ClickType.keys()[click_type]
	var extra = ""
	
	if has_shift():
		extra += "+SHIFT"
	if has_ctrl():
		extra += "+CTRL"
	if has_alt():
		extra += "+ALT"
	if is_drag_action():
		extra += " (dist:%.1f)" % get_drag_distance()
	if is_hold_action():
		extra += " (%.1fs)" % get_hold_duration()
	
	return "ClickContext[%s%s]: %s[%d]" % [
		action_name, extra, source_container_id, source_slot_index
	]

func debug_sequence_data():
	"""Debug les données de séquence"""
	print("🔍 Sequence Debug [%s]:" % sequence_id)
	if is_drag_action():
		print("   - Type: DRAG")
		print("   - Distance: %.1f" % get_drag_distance())
		print("   - Start: %s" % get_drag_start_pos())
		print("   - Slots visités: %s" % get_slots_visited())
	elif is_hold_action():
		print("   - Type: HOLD")
		print("   - Durée: %.1fs" % get_hold_duration())
		print("   - Slots visités: %s" % get_slots_visited())
	else:
		print("   - Type: ACTION SIMPLE")
	print("   - Modifiers: %s" % modifiers)
