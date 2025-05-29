# MovementStateBase.gd - Classe de base pour tous les états de mouvement
extends State
class_name MovementStateBase

# Propriétés communes
var last_speed: float = 0.0
var last_surface: String = ""

# Méthodes communes à override si nécessaire
func get_movement_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func should_jump() -> bool:
	return Input.is_action_just_pressed("jump") and player.is_on_floor()

func should_run() -> bool:
	return Input.is_action_pressed("run")

func get_movement_speed() -> float:
	return player.run_speed if should_run() else player.walk_speed

func apply_common_physics(delta: float):
	player.apply_gravity(delta)

func handle_common_transitions():
	# Jump est prioritaire dans tous les états
	if should_jump():
		StateAudioHelper.start_state_audio("jumping", player)
		state_machine.change_state("jumping")
		return true
	return false

func apply_movement_with_direction(delta: float):
	var input_dir = get_movement_input()
	var speed = get_movement_speed()
	var direction = player.get_movement_direction_from_camera()
	
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()

# Gestion audio automatique
func update_audio_if_needed():
	var current_speed = get_movement_speed()
	var current_surface = StateAudioHelper._detect_surface(player)
	
	if abs(current_speed - last_speed) > 0.5 or current_surface != last_surface:
		_refresh_audio(current_speed, current_surface)
		last_speed = current_speed
		last_surface = current_surface

func _refresh_audio(speed: float, surface: String):
	# Override dans les classes enfants si nécessaire
	pass

# Template method pattern pour les états
func physics_update(delta):
	apply_common_physics(delta)
	
	if handle_common_transitions():
		return
	
	handle_state_specific_logic(delta)

# À implémenter dans chaque état
func handle_state_specific_logic(_delta: float):
	pass
