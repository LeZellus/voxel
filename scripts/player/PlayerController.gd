# PlayerController.gd - Version améliorée utilisant les nouvelles classes
extends CharacterBody3D

# Configuration depuis GameConfig
@export var walk_speed: float = GameConfig.PLAYER.walk_speed
@export var run_speed: float = GameConfig.PLAYER.run_speed
@export var jump_velocity: float = GameConfig.PLAYER.jump_velocity
@export var rotation_speed: float = GameConfig.PLAYER.rotation_speed

@export var mouse_sensitivity: float = GameConfig.CAMERA.mouse_sensitivity
@export var min_vertical_angle: float = GameConfig.CAMERA.min_vertical_angle
@export var max_vertical_angle: float = GameConfig.CAMERA.max_vertical_angle

# Composants avec validation
@onready var spring_arm: SpringArm3D = ValidationUtils.get_node_safe(self, "SpringArm3D")
@onready var camera: Camera3D = ValidationUtils.get_node_safe(spring_arm, "Camera3D") if spring_arm else null
@onready var state_machine: StateMachine = ValidationUtils.get_node_safe(self, "StateMachine")
@onready var model_root: Node3D = ValidationUtils.get_node_safe(self, "CharacterSkin")
@onready var animation_player: AnimationPlayer = $CharacterSkin/AnimationPlayer 

var current_speed: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	GameConfig.validate_config()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_spring_arm()
	add_to_group(GameConfig.GROUPS.player)

func setup_spring_arm():
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "setup_spring_arm"):
		return
		
	var config = GameConfig.CAMERA
	spring_arm.spring_length = config.spring_length
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.5
	spring_arm.rotation.x = -0.3

func _unhandled_input(event: InputEvent):
	handle_camera_input(event)
	
	if state_machine and state_machine.current_state:
		state_machine.current_state.handle_input(event)

func handle_camera_input(event: InputEvent):
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "camera_input"):
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_vertical_angle, max_vertical_angle)
	
	elif event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		_handle_zoom(event)
	
	elif event.is_action_pressed("ui_cancel"):
		_toggle_mouse_mode()

func _handle_zoom(event: InputEventMouseButton):
	var config = GameConfig.CAMERA
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length - config.zoom_step, 
			config.zoom_min, 
			config.zoom_max
		)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length + config.zoom_step, 
			config.zoom_min, 
			config.zoom_max
		)

func _toggle_mouse_mode():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Méthodes de mouvement simplifiées
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func apply_movement(direction: Vector3, speed: float, delta: float = 0.0):
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		if delta > 0 and ValidationUtils.validate_node(model_root, "ModelRoot", "apply_movement"):
			var target_rotation = atan2(-direction.x, -direction.z)
			model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rotation, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func get_movement_direction_from_camera() -> Vector3:
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "get_movement_direction"):
		return Vector3.ZERO
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() == 0:
		return Vector3.ZERO
	
	var camera_forward = -spring_arm.global_transform.basis.z
	var camera_right = spring_arm.global_transform.basis.x
	
	var direction = (camera_right * input_dir.x + camera_forward * -input_dir.y).normalized()
	direction.y = 0
	
	return direction
