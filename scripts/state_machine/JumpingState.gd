extends State
class_name JumpingState

func enter():
	print("Joueur: Saut")
	player.velocity.y = player.jump_velocity

func physics_update(delta):
	player.apply_gravity(delta)
	
	# Mouvement en l'air
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = player.walk_speed * 0.8  # Mouvement réduit en l'air
	
	player.apply_movement(direction, speed)
	player.move_and_slide()
	
	# Transition vers idle/walking quand on atterrit
	if player.is_on_floor() and player.velocity.y <= 0:
		var input_length = input_dir.length()
		if input_length > 0:
			state_machine.change_state("walking")
		else:
			state_machine.change_state("idle")

func handle_input(event):
	# Caméra gérée par PlayerController
	pass
