extends MovementStateBase
class_name JumpingState

func on_enter():
	player.velocity.y = player.jump_velocity

func physics_update(delta):
	player.apply_gravity(delta)
	
	# Mouvement en l'air - UTILISER LE NOUVEAU SYSTÈME
	var direction = player.get_movement_direction_from_camera()
	var speed = player.walk_speed * 0.8  # Mouvement réduit en l'air
	
	# AJOUTER LE PARAMÈTRE DELTA
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()
	
	# Transition vers idle/walking quand on atterrit
	if player.is_on_floor() and player.velocity.y <= 0:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var input_length = input_dir.length()
		if input_length > 0:
			state_machine.change_state("walking")
		else:
			state_machine.change_state("idle")
			
func configure_state():
	"""Configuration spécifique à la marche"""
	configure_for_jumping()

func handle_input(_event):
	# Caméra gérée par PlayerController
	pass
