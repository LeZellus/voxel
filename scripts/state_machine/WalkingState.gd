extends State
class_name WalkingState

@onready var dust_particles: GPUParticles3D = %DustParticles

var last_speed: float = 0.0
var last_surface: String = ""

# Nouvelles variables pour la course
var base_model_rotation: Vector3
var target_lean_angle: float = 0.0
var lean_speed: float = 8.0
var running_lean: float = -0.15  # Radians (~8.5 degrés)

func enter():
	if DebugHelper.check_node(player.animation_player, "AnimationPlayer", "WalkingState.enter"):
		player.animation_player.play("Run")
		# Animation plus rapide par défaut
		update_animation_speed()
	
	dust_particles.emitting = true
	
	# Sauvegarder la rotation de base du modèle
	if player.model_root:
		base_model_rotation = player.model_root.rotation
	
	# Audio simplifié
	SimpleAudioHelper.start_footsteps_for_state("walking", player, player.walk_speed)
	last_speed = player.walk_speed
	last_surface = SurfaceDetector.detect_surface_under_player(player)

func physics_update(delta):
	player.apply_gravity(delta)
	
	# Input simplifié
	if not InputHelper.is_moving():
		state_machine.change_state("idle")
		return
	
	if InputHelper.should_jump() and player.is_on_floor():
		SimpleAudioHelper.play_action_sound("jump")
		state_machine.change_state("jumping")
		return
	
	# Mettre à jour l'animation et l'inclinaison selon la vitesse
	update_animation_speed()
	update_model_lean(delta)
	
	# Mouvement
	var speed = player.run_speed if InputHelper.should_run() else player.walk_speed
	var direction = player.get_movement_direction_from_camera()
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()
	
	# Audio automatique avec détection course/marche
	var state_name = "running" if InputHelper.should_run() else "walking"
	
	if abs(speed - last_speed) > 0.5:
		SimpleAudioHelper.start_footsteps_for_state(state_name, player, speed)
		last_speed = speed
	
	AudioManager.update_footsteps()

func update_animation_speed():
	if not player.animation_player:
		return
		
	if InputHelper.should_run():
		player.animation_player.speed_scale = 6.0  # Plus rapide en course
		target_lean_angle = running_lean
	else:
		player.animation_player.speed_scale = 4.0  # Normal en marche
		target_lean_angle = 0.0

func update_model_lean(delta: float):
	if not player.model_root:
		return
		
	# Interpolation fluide vers l'angle cible
	var current_lean = player.model_root.rotation.x
	var new_lean = lerp_angle(current_lean, target_lean_angle, lean_speed * delta)
	
	player.model_root.rotation.x = new_lean

func exit():
	if player.animation_player:
		player.animation_player.stop()
	
	# Remettre le modèle droit
	if player.model_root:
		player.model_root.rotation = base_model_rotation
		
	dust_particles.emitting = false
	AudioManager.stop_footsteps()
	last_speed = 0.0
	last_surface = ""
