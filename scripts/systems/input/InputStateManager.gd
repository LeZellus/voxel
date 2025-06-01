# scripts/systems/input/InputStateManager.gd
class_name InputStateManager
extends RefCounted

# === TYPES D'ACTIONS ===
enum ActionType {
	SIMPLE_LEFT_CLICK,
	SIMPLE_RIGHT_CLICK,
	MIDDLE_CLICK,
	DOUBLE_LEFT_CLICK,
	SHIFT_LEFT_CLICK,
	LEFT_DRAG_START,
	LEFT_DRAG_CONTINUE,
	LEFT_DRAG_END,
	RIGHT_HOLD_START,
	RIGHT_HOLD_CONTINUE,
	RIGHT_HOLD_END
}

const SIMPLE_LEFT_CLICK = ActionType.SIMPLE_LEFT_CLICK
const SIMPLE_RIGHT_CLICK = ActionType.SIMPLE_RIGHT_CLICK
const MIDDLE_CLICK = ActionType.MIDDLE_CLICK

# === ÉTAT ===
var mouse_state = {
	"left_pressed": false,
	"right_pressed": false,
	"left_press_time": 0.0,
	"right_press_time": 0.0,
	"last_left_click_time": 0.0,
	"drag_threshold": 5.0,
	"double_click_time": 0.4,
	"hold_threshold": 0.3,
	"initial_press_pos": Vector2.ZERO,
	"is_dragging": false,
	"is_holding": false
}

var modifiers = {
	"shift": false,
	"ctrl": false,
	"alt": false
}

signal action_detected(action_type: ActionType, event: InputEvent, context: Dictionary)

# === TRAITEMENT PRINCIPAL ===
func process_input(event: InputEvent) -> ActionType:
	print("🐛 INPUT DEBUG: %s" % event.get_class())
	
	# Ne traiter que les VRAIS événements de clic
	if event is InputEventMouseButton:
		print("🐛 MOUSE BUTTON: button=%d, pressed=%s" % [event.button_index, event.pressed])
		return _process_mouse_button(event)
	elif event is InputEventMouseMotion:
		print("🐛 MOUSE MOTION - NE DEVRAIT PAS CRÉER DE CLICS")
		return _process_mouse_motion(event)
	
	return ActionType.SIMPLE_LEFT_CLICK if event is InputEventMouseButton else ActionType.SIMPLE_LEFT_CLICK  # ❌ PROBLÈME ICI !

# === TRAITEMENT BOUTONS SOURIS ===
func _process_mouse_button(event: InputEventMouseButton) -> ActionType:
	var current_time = Time.get_unix_time_from_system()
	
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return _process_left_button(event, current_time)
		MOUSE_BUTTON_RIGHT:
			return _process_right_button(event, current_time)
		MOUSE_BUTTON_MIDDLE:
			if not event.pressed:
				return ActionType.MIDDLE_CLICK
	
	return ActionType.SIMPLE_LEFT_CLICK  # Fallback

func _process_left_button(event: InputEventMouseButton, current_time: float) -> ActionType:
	if event.pressed:
		# === PRESS ===
		mouse_state.left_pressed = true
		mouse_state.left_press_time = current_time
		mouse_state.initial_press_pos = event.global_position
		mouse_state.is_dragging = false
		
		# Détecter double-clic
		var time_since_last = current_time - mouse_state.last_left_click_time
		if time_since_last <= mouse_state.double_click_time:
			mouse_state.last_left_click_time = 0.0  # Reset pour éviter triple-clic
			return ActionType.DOUBLE_LEFT_CLICK if not modifiers.shift else ActionType.SHIFT_LEFT_CLICK
		
		mouse_state.last_left_click_time = current_time
		return ActionType.SIMPLE_LEFT_CLICK  # Temporaire, peut devenir drag
	
	else:
		# === RELEASE ===
		mouse_state.left_pressed = false
		
		if mouse_state.is_dragging:
			mouse_state.is_dragging = false
			return ActionType.LEFT_DRAG_END
		
		# Clic simple avec modificateur
		if modifiers.shift:
			return ActionType.SHIFT_LEFT_CLICK
		
		return ActionType.SIMPLE_LEFT_CLICK

func _process_right_button(event: InputEventMouseButton, current_time: float) -> ActionType:
	if event.pressed:
		# === PRESS ===
		mouse_state.right_pressed = true
		mouse_state.right_press_time = current_time
		mouse_state.is_holding = false
		return ActionType.SIMPLE_RIGHT_CLICK  # Temporaire, peut devenir hold
	
	else:
		# === RELEASE ===
		mouse_state.right_pressed = false
		
		if mouse_state.is_holding:
			mouse_state.is_holding = false
			return ActionType.RIGHT_HOLD_END
		
		return ActionType.SIMPLE_RIGHT_CLICK

# === TRAITEMENT MOUVEMENT ===
func _process_mouse_motion(event: InputEventMouseMotion) -> ActionType:
	var current_time = Time.get_unix_time_from_system()
	
	# Détecter drag (clic gauche maintenu + mouvement)
	if mouse_state.left_pressed and not mouse_state.is_dragging:
		var distance = event.global_position.distance_to(mouse_state.initial_press_pos)
		if distance > mouse_state.drag_threshold:
			mouse_state.is_dragging = true
			return ActionType.LEFT_DRAG_START
	
	elif mouse_state.is_dragging:
		return ActionType.LEFT_DRAG_CONTINUE
	
	# Détecter hold (clic droit maintenu + temps)
	if mouse_state.right_pressed and not mouse_state.is_holding:
		var hold_time = current_time - mouse_state.right_press_time
		if hold_time > mouse_state.hold_threshold:
			mouse_state.is_holding = true
			return ActionType.RIGHT_HOLD_START
	
	elif mouse_state.is_holding:
		return ActionType.RIGHT_HOLD_CONTINUE
	
	return ActionType.SIMPLE_LEFT_CLICK  # Pas d'action spéciale

# === UTILITAIRES ===
func _update_modifiers(event: InputEvent):
	"""Met à jour l'état des modificateurs"""
	if event is InputEventKey:
		match event.keycode:
			KEY_SHIFT:
				modifiers.shift = event.pressed
			KEY_CTRL:
				modifiers.ctrl = event.pressed
			KEY_ALT:
				modifiers.alt = event.pressed
	
	# Alternative pour les événements souris
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		modifiers.shift = Input.is_key_pressed(KEY_SHIFT)
		modifiers.ctrl = Input.is_key_pressed(KEY_CTRL)
		modifiers.alt = Input.is_key_pressed(KEY_ALT)

func get_current_modifiers() -> Dictionary:
	"""Retourne l'état actuel des modificateurs"""
	return modifiers.duplicate()

func is_in_drag_state() -> bool:
	"""Vérifie si on est en train de drag"""
	return mouse_state.is_dragging

func is_in_hold_state() -> bool:
	"""Vérifie si on est en train de hold"""
	return mouse_state.is_holding

func reset_state():
	"""Reset complet de l'état"""
	mouse_state.left_pressed = false
	mouse_state.right_pressed = false
	mouse_state.is_dragging = false
	mouse_state.is_holding = false
