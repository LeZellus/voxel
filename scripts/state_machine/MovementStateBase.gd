# MovementStateBase.gd - VERSION SIMPLIFIÉE (sans @onready problématiques)
extends State
class_name MovementStateBase

# === PROPRIÉTÉS COMMUNES ===
var last_speed: float = 0.0
var last_surface: String = ""
var audio_state_name: String = "walking"
var animation_name: String = "Run"
var base_animation_speed: float = 4.0
var running_animation_speed: float = 6.0
var base_model_rotation: Vector3
var target_lean_angle: float = 0.0
var lean_speed: float = 8.0
var running_lean: float = -0.15

# === GETTERS SÉCURISÉS (pas de @onready) ===
func get_dust_particles() -> GPUParticles3D:
	if not player:
		return null
	return player.get_node_or_null("DustEffects/DustParticles")

func get_model_root() -> Node3D:
	if not player:
		return null
	return player.model_root

func get_animation_player() -> AnimationPlayer:
	if not player:
		return null
	return player.animation_player

# === MÉTHODES COMMUNES ===
func common_enter():
	"""Appeler dans enter() des classes filles"""
	_start_animation()
	_start_audio()
	_start_effects()
	_save_model_state()

func common_exit():
	"""Appeler dans exit() des classes filles"""
	_stop_animation()
	_stop_audio()
	_stop_effects()
	_restore_model_state()

func common_physics_update(delta: float):
	"""Logique commune à tous les états de mouvement"""
	player.apply_gravity(delta)
	
	# D'abord la logique spécifique de l'état
	handle_specific_logic(delta)
	
	# Puis les transitions communes (jump seulement)
	if InputHelper.should_jump() and player.is_on_floor():
		SimpleAudioHelper.play_action_sound("jump")
		state_machine.change_state("jumping")
		return
	
	# Mise à jour des systèmes
	_update_animation()
	_update_model_lean(delta)
	_update_audio()

# === TRANSITIONS COMMUNES ===
func _handle_common_transitions() -> bool:
	if InputHelper.should_jump() and player.is_on_floor():
		SimpleAudioHelper.play_action_sound("jump")
		state_machine.change_state("jumping")
		return true
	
	if not InputHelper.is_moving():
		state_machine.change_state("idle")
		return true
		
	return false

# === GESTION ANIMATION ===
func _start_animation():
	var anim_player = get_animation_player()
	if not anim_player:
		print("⚠️ AnimationPlayer non trouvé, animation ignorée")
		return
		
	anim_player.play(animation_name)
	_update_animation()

func _stop_animation():
	var anim_player = get_animation_player()
	if anim_player:
		anim_player.stop()

func _update_animation():
	var anim_player = get_animation_player()
	if not anim_player:
		return
		
	if InputHelper.should_run():
		anim_player.speed_scale = running_animation_speed
		target_lean_angle = running_lean
	else:
		anim_player.speed_scale = base_animation_speed
		target_lean_angle = 0.0

# === GESTION AUDIO ===
func _start_audio():
	var initial_speed = player.run_speed if InputHelper.should_run() else player.walk_speed
	SimpleAudioHelper.start_footsteps_for_state(audio_state_name, player, initial_speed)
	last_speed = initial_speed
	last_surface = SurfaceDetector.detect_surface_under_player(player)

func _stop_audio():
	AudioManager.stop_footsteps()
	last_speed = 0.0
	last_surface = ""

func _update_audio():
	var current_state = "running" if InputHelper.should_run() else "walking"
	var current_speed = player.run_speed if InputHelper.should_run() else player.walk_speed
	
	if abs(current_speed - last_speed) > 0.5:
		SimpleAudioHelper.start_footsteps_for_state(current_state, player, current_speed)
		last_speed = current_speed
	
	AudioManager.update_footsteps()

# === GESTION EFFETS VISUELS ===
func _start_effects():
	var particles = get_dust_particles()
	if particles:
		particles.emitting = true

func _stop_effects():
	var particles = get_dust_particles()
	if particles:
		particles.emitting = false

# === GESTION MODÈLE 3D ===
func _save_model_state():
	var model = get_model_root()
	if model:
		base_model_rotation = model.rotation

func _restore_model_state():
	var model = get_model_root()
	if model:
		model.rotation = base_model_rotation

func _update_model_lean(delta: float):
	var model = get_model_root()
	if not model:
		return
		
	var current_lean = model.rotation.x
	var new_lean = lerp_angle(current_lean, target_lean_angle, lean_speed * delta)
	model.rotation.x = new_lean

# === MOUVEMENT COMMUN ===
func apply_common_movement(delta: float):
	var speed = player.run_speed if InputHelper.should_run() else player.walk_speed
	var direction = player.get_movement_direction_from_camera()
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()

# === CONFIGURATION ===
func configure_for_walking():
	audio_state_name = "walking"
	animation_name = "Run"
	base_animation_speed = 4.0
	running_animation_speed = 6.0

# === TEMPLATE METHODS ===
func physics_update(delta):
	common_physics_update(delta)
	handle_specific_logic(delta)

func enter():
	configure_state()
	common_enter()
	on_enter()

func exit():
	common_exit()
	on_exit()

# === HOOKS POUR LES CLASSES FILLES ===
func configure_state():
	configure_for_walking()

func handle_specific_logic(_delta: float):
	apply_common_movement(_delta)

func on_enter():
	pass

func on_exit():
	pass
