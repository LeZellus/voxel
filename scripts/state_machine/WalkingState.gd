extends State
class_name WalkingState

@onready var dust_particles: GPUParticles3D = %DustParticles

func enter():
	if player.animation_player:
		player.animation_player.play("Run")
		player.animation_player.speed_scale = 4.0
	
	dust_particles.emitting = true
	
	# 🎬 CONFIGURER VOS POSITIONS EXACTES
	AudioManager.set_footstep_positions([0.2, 1])  # Vos positions !
	AudioManager.set_footstep_tolerance(0.05)        # Tolérance 50ms
	AudioManager.set_footstep_debug(true)
	
	AudioManager.set_footstep_volume(0.05)
	AudioManager.start_footsteps(player.walk_speed, "wood", player.animation_player)

func physics_update(delta):
	player.apply_gravity(delta)
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() == 0:
		state_machine.change_state("idle")
		return
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		AudioManager.play_player_sound("jump", "actions")
		state_machine.change_state("jumping")
		return
	
	# 🔧 TESTS DE TOLÉRANCE EN TEMPS RÉEL
	if Input.is_action_just_pressed("ui_right"):  # Barre d'espace
		AudioManager.set_footstep_tolerance(0.1)   # Tolérance plus large
		print("🔧 Tolérance élargie à 100ms")
	
	if Input.is_action_just_pressed("ui_down"):  # Échap
		AudioManager.set_footstep_tolerance(0.02)  # Tolérance très précise
		print("🔧 Tolérance réduite à 20ms")
	
	if Input.is_action_just_pressed("ui_up"):      # Flèche haut
		AudioManager.set_footstep_tolerance(0.05)  # Tolérance normale
		print("🔧 Tolérance normale 50ms")
	
	var speed = player.run_speed if Input.is_action_pressed("run") else player.walk_speed
	var direction = player.get_movement_direction_from_camera()
	
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()
	
	# 🎬 MISE À JOUR SIMPLE
	AudioManager.update_footsteps()

func exit():
	AudioManager.set_footstep_debug(false)
	
	if player.animation_player:
		player.animation_player.stop()
	
	dust_particles.emitting = false
	AudioManager.stop_footsteps()
