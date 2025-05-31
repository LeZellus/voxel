# WalkingState.gd - VERSION SIMPLE QUI FONCTIONNE
extends State
class_name WalkingState

func enter():
	# Démarrer l'animation
	if player.animation_player:
		player.animation_player.play("Run")
	
	# Démarrer l'audio
	player.start_footsteps("grass")
	
	# Démarrer les effets
	var particles = player.get_node_or_null("DustEffects/DustParticles")
	if particles:
		particles.emitting = true

func exit():
	# Arrêter l'audio
	player.stop_footsteps()
	
	# Arrêter les effets
	var particles = player.get_node_or_null("DustEffects/DustParticles")
	if particles:
		particles.emitting = false

func physics_update(delta):
	# Gravité
	player.apply_gravity(delta)
	
	# Récupérer input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Transition vers idle si pas d'input
	if input_dir.length() == 0:
		state_machine.change_state("idle")
		return
	
	# Transition vers jump
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.play_action_sound("jump")
		state_machine.change_state("jumping")
		return
	
	# Mouvement
	var speed = ConstantsPlayer.RUN_SPEED if Input.is_action_pressed("run") else ConstantsPlayer.WALK_SPEED
	var direction = player.get_movement_direction_from_camera()
	
	if direction.length() > 0:
		player.apply_movement(direction, speed, delta)
		
		# Mettre à jour la vitesse d'animation selon la course
		if player.animation_player:
			if Input.is_action_pressed("run"):
				player.animation_player.speed_scale = 6.0
			else:
				player.animation_player.speed_scale = 4.0
	
	# Appliquer le mouvement
	player.move_and_slide()
	
	# Mettre à jour l'audio
	player.update_footsteps()

func handle_input(event):
	# Gestion caméra déjà dans PlayerController
	pass
