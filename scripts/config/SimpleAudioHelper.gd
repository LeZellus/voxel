# SimpleAudioHelper.gd
class_name SimpleAudioHelper

# Configuration simple par état
static var STATE_SOUNDS = {
	"walking": {
		"positions": [0.3, 1.0],
		"tolerance": 0.05,
		"volume": 0.1
	},
	"running": {
		"positions": [0.2, 0.7], 
		"tolerance": 0.04,
		"volume": 0.15
	}
}

# Sons d'action simples
static var ACTION_SOUNDS = {
	"jump": "jump",
	"land": "land", 
	"pickup": "pickup"
}

# Démarre les sons de pas pour un état
static func start_footsteps_for_state(state_name: String, player: CharacterBody3D, speed: float):
	var config = STATE_SOUNDS.get(state_name.to_lower())
	if not config:
		DebugHelper.log_warning("SimpleAudioHelper", "Config audio introuvable pour: " + state_name)
		return
	
	AudioManager.set_footstep_positions(config.positions)
	AudioManager.set_footstep_tolerance(config.tolerance)
	AudioManager.set_footstep_volume(config.volume)
	
	var surface = SurfaceDetector.detect_surface_under_player(player)
	AudioManager.start_footsteps(speed, surface, player.animation_player)

# Joue un son d'action
static func play_action_sound(action: String, volume: float = 1.0):
	var sound_name = ACTION_SOUNDS.get(action)
	if not sound_name:
		DebugHelper.log_warning("SimpleAudioHelper", "Son d'action introuvable: " + action)
		return
	
	AudioManager.play_player_sound(sound_name, "actions", volume)

# Met à jour l'audio si surface ou vitesse change
static func update_footsteps_if_needed(player: CharacterBody3D, last_surface: String, last_speed: float, current_speed: float) -> String:
	var current_surface = SurfaceDetector.detect_surface_under_player(player)
	
	if current_surface != last_surface or abs(current_speed - last_speed) > 0.5:
		AudioManager.stop_footsteps()
		var state_name = "running" if InputHelper.should_run() else "walking"
		start_footsteps_for_state(state_name, player, current_speed)
	
	return current_surface
