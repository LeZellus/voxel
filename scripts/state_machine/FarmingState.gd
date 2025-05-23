extends State
class_name FarmingState

var interaction_range: float = 3.0
var interaction_ray: RayCast3D  # Pas de @onready ici !

func _state_ready():
	if not interaction_ray and player:
		interaction_ray = player.get_node_or_null("InteractionRay")

func enter():
	print("Joueur: Mode farming")

func physics_update(delta):
	player.apply_gravity(delta)
	
	# Mouvement normal
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Transition vers autres états
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		state_machine.change_state("jumping")
		return
	
	# Mouvement
	if input_dir.length() > 0:
		var speed = player.run_speed if Input.is_action_pressed("run") else player.walk_speed
		var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		player.apply_movement(direction, speed)
	else:
		player.apply_movement(Vector3.ZERO, 0)
	
	player.move_and_slide()

func handle_input(event):
	player.handle_camera_input(event)
	
	# Actions farming
	if event.is_action_pressed("interact"):
		try_farming_action()
	
	# Sortir du mode farming
	if event.is_action_pressed("farming_mode_toggle"):
		state_machine.change_state("idle")

func try_farming_action():
	if interaction_ray and interaction_ray.is_colliding():
		print("Action farming à la position: ", interaction_ray.get_collision_point())
		# Ici on ajoutera la logique farming plus tard
