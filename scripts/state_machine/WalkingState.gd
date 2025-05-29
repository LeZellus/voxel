# WalkingState.gd - Version simplifiée utilisant MovementStateBase
extends MovementStateBase
class_name WalkingState

@onready var dust_particles: GPUParticles3D = %DustParticles

func enter():
	if player.animation_player:
		player.animation_player.play("Run")
		player.animation_player.speed_scale = 4.0
	
	dust_particles.emitting = true
	StateAudioHelper.start_state_audio("walking", player, player.walk_speed)

func exit():
	if player.animation_player:
		player.animation_player.stop()
	
	dust_particles.emitting = false
	AudioManager.stop_footsteps()

func handle_state_specific_logic(delta: float):
	var input_dir = get_movement_input()
	
	# Transition vers idle si pas d'input
	if input_dir.length() == 0:
		state_machine.change_state("idle")
		return
	
	# Mouvement et audio
	apply_movement_with_direction(delta)
	update_audio_if_needed()
	AudioManager.update_footsteps()

# Override pour l'audio spécifique walking
func _refresh_audio(speed: float, surface: String):
	var state_name = "running" if should_run() else "walking"
	StateAudioHelper.start_state_audio(state_name, player, speed)
