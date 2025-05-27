extends State
class_name WalkingState

func enter():
	if player.animation_player:
		player.animation_player.play("ArmatureAction")
		player.animation_player.speed_scale = 2.0

func physics_update(delta):
	player.apply_gravity(delta)
	
	# Input mouvement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Vérifier transitions
	if input_dir.length() == 0:
		state_machine.change_state("idle")
		return
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		state_machine.change_state("jumping")
		return
	
	# Vitesse selon si on court ou non
	var speed = player.run_speed if Input.is_action_pressed("run") else player.walk_speed
	
	# Direction relative au joueur
	var direction = player.get_movement_direction_from_camera()
	
	# Appliquer mouvement
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()

func handle_input(_event):
	# Caméra gérée par PlayerController
	pass
	
func exit():
	# Arrêter l'animation si nécessaire
	if player.animation_player:
		player.animation_player.stop()
