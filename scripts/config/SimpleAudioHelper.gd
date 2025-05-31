# SimpleAudioHelper.gd - VERSION CORRIGÉE POUR AUDIOSYSTEM
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

# Démarre les sons de pas pour un état - VERSION SIMPLIFIÉE
static func start_footsteps_for_state(state_name: String, player: CharacterBody3D, speed: float):
	var config = STATE_SOUNDS.get(state_name.to_lower())
	if not config:
		DebugHelper.log_warning("SimpleAudioHelper", "Config audio introuvable pour: " + state_name)
		return
	
	# SIMPLIFIÉ : Plus besoin de configurer les positions/tolerance
	# AudioSystem les gère en interne
	
	var surface = SurfaceDetector.detect_surface_under_player(player)
	
	# NOUVELLE SIGNATURE : start_footsteps(animation_player, surface)
	if player.animation_player:
		AudioSystem.start_footsteps(player.animation_player, surface)
	else:
		DebugHelper.log_warning("SimpleAudioHelper", "AnimationPlayer manquant")

# Joue un son d'action - VERSION CORRIGÉE
static func play_action_sound(action: String, volume: float = 1.0):
	var sound_name = ACTION_SOUNDS.get(action)
	if not sound_name:
		DebugHelper.log_warning("SimpleAudioHelper", "Son d'action introuvable: " + action)
		return
	
	# NOUVELLE SIGNATURE : play_player_sound(sound_name, volume)
	AudioSystem.play_player_sound(sound_name, volume)

# Met à jour l'audio si surface ou vitesse change - VERSION SIMPLIFIÉE
static func update_footsteps_if_needed(player: CharacterBody3D, last_surface: String, last_speed: float, current_speed: float) -> String:
	var current_surface = SurfaceDetector.detect_surface_under_player(player)
	
	if current_surface != last_surface or abs(current_speed - last_speed) > 0.5:
		# SIMPLIFIÉ : Juste stop et restart
		AudioSystem.stop_footsteps()
		var state_name = "running" if InputHelper.should_run() else "walking"
		start_footsteps_for_state(state_name, player, current_speed)
	
	return current_surface

# === ALIAS POUR COMPATIBILITÉ ===
static func start_footsteps(anim_player: AnimationPlayer, surface: String = "grass"):
	"""Alias direct pour AudioSystem"""
	AudioSystem.start_footsteps(anim_player, surface)

static func stop_footsteps():
	"""Alias direct pour AudioSystem"""
	AudioSystem.stop_footsteps()

static func update_footsteps():
	"""Alias direct pour AudioSystem"""
	AudioSystem.update_footsteps()
