extends CharacterBody3D

# Configuration mouvement
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5

# Configuration caméra
@export var mouse_sensitivity: float = 0.002
@export_range(-90.0, 90.0, 1.0, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(-90.0, 90.0, 1.0, "radians_as_degrees") var max_vertical_angle: float = PI/4

# Composants
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var state_machine: StateMachine = $StateMachine

# Variables partagées
var current_speed: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_spring_arm()
	add_to_group("player")

func setup_spring_arm():
	spring_arm.spring_length = 8.0
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.5
	spring_arm.rotation.x = -0.3

# GESTION INPUTS DANS LE PLAYERCONTROLLER (pas dans les states)
func _unhandled_input(event: InputEvent):
	handle_camera_input(event)
	
	# Déléguer l'input à l'état actuel si nécessaire
	if state_machine.current_state:
		state_machine.current_state.handle_input(event)

func handle_camera_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_vertical_angle, max_vertical_angle)
	
	if event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 1.0, 3.0, 15.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 1.0, 3.0, 15.0)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func apply_movement(direction: Vector3, speed: float):
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
