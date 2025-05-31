# JumpingState.gd - VERSION SIMPLE QUI FONCTIONNE
extends State
class_name JumpingState

func enter():
	# Impulse de saut
	player.velocity.y = ConstantsPlayer.JUMP_VELOCITY
	
	# Son de saut
	player.play_action_sound("jump")
	
	# Animation de saut si elle existe
	if player.animation_player:
		player.animation_player.play("Jump")

func exit():
	pass

func physics_update(delta):
	# Gravité
	player.apply_gravity(delta)
	
	# Mouvement en l'air (contrôle réduit)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() > 0:
		var direction = player.get_movement_direction_from_camera()
		var air_speed = ConstantsPlayer.WALK_SPEED * ConstantsPlayer.IN_AIR_FRICTION  # Mouvement réduit en l'air
		player.apply_movement(direction, air_speed, delta)
	
	# Appliquer le mouvement
	player.move_and_slide()
	
	# Transition à l'atterrissage
	if player.is_on_floor() and player.velocity.y <= 0:
		player.play_action_sound("land")  # Son d'atterrissage
		
		# Vérifier où aller après l'atterrissage
		if InputHelper.is_moving():
			state_machine.change_state("walking")
		else:
			state_machine.change_state("idle")
