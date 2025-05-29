# InputHelper.gd
class_name InputHelper

# Movement
static func get_movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

static func is_moving() -> bool:
	return get_movement_input().length() > 0

static func should_run() -> bool:
	return Input.is_action_pressed("run")

static func should_jump() -> bool:
	return Input.is_action_just_pressed("jump")

# UI
static func should_interact() -> bool:
	return Input.is_action_just_pressed("interact")

# Camera
static func is_camera_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

static func should_toggle_mouse() -> bool:
	return Input.is_action_pressed("ui_cancel")
