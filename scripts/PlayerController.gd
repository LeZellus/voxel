# PlayerController.gd - Caméra Spring Arm style Godot/Unreal
extends CharacterBody3D

# Configuration mouvement
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var jump_velocity: float = 4.5

# Configuration Spring Arm Camera
@export var mouse_sensitivity: float = 0.002
@export_range(-90.0, 90.0, 1.0, "radians_as_degrees") var min_vertical_angle: float = -PI/2
@export_range(-90.0, 90.0, 1.0, "radians_as_degrees") var max_vertical_angle: float = PI/4

# Nœuds Spring Arm
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var current_speed: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_spring_arm()

func setup_spring_arm():
	# Configuration Spring Arm (ajuster selon vos préférences)
	spring_arm.spring_length = 8.0      # Distance caméra
	spring_arm.collision_mask = 1       # Collision avec le monde
	spring_arm.margin = 0.5             # Marge collision
	
	# Rotation initiale (vue légèrement du dessus)
	spring_arm.rotation.x = -0.3

func _unhandled_input(event: InputEvent) -> void:
	# Contrôle caméra avec souris
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotation horizontale (Y axis)
		rotation.y -= event.relative.x * mouse_sensitivity
		
		# Rotation verticale (X axis) sur le SpringArm
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_vertical_angle, max_vertical_angle)
	
	# Zoom avec molette
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 1.0, 3.0, 15.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 1.0, 3.0, 15.0)
	
	# Toggle mouse capture
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Vitesse
	current_speed = run_speed if Input.is_action_pressed("run") else walk_speed
	
	# Input mouvement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() > 0.0:
		# MOUVEMENT RELATIF À L'ORIENTATION DU JOUEUR (pas de la caméra)
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
