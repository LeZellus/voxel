# StateAudioHelper.gd - Centralise la gestion audio des états
class_name StateAudioHelper
extends RefCounted

# Configuration audio par état
static var STATE_AUDIO_CONFIG = {
	"walking": {
		"footstep_positions": [0.3, 1.0],
		"footstep_tolerance": 0.05,
		"footstep_volume": 0.1,
		"surface": "wood"
	},
	"running": {
		"footstep_positions": [0.2, 0.7],
		"footstep_tolerance": 0.04,
		"footstep_volume": 0.15,
		"surface": "wood"
	},
	"jumping": {
		"sound": "jump",
		"category": "actions",
		"volume": 0.8
	},
	"landing": {
		"sound": "land",
		"category": "actions", 
		"volume": 0.6
	}
}

# Démarre l'audio pour un état donné
static func start_state_audio(state_name: String, player: CharacterBody3D, speed: float = 0.0):
	var config = STATE_AUDIO_CONFIG.get(state_name.to_lower())
	if not config:
		return
	
	match state_name.to_lower():
		"walking", "running":
			_setup_footsteps(config, player, speed)
		"jumping", "landing":
			_play_action_sound(config)

# Configure les pas
static func _setup_footsteps(config: Dictionary, player: CharacterBody3D, speed: float):
	AudioManager.set_footstep_positions(config.footstep_positions)
	AudioManager.set_footstep_tolerance(config.footstep_tolerance)
	AudioManager.set_footstep_volume(config.footstep_volume)
	
	var surface = _detect_surface(player)
	AudioManager.start_footsteps(speed, surface, player.animation_player)

# Joue un son d'action
static func _play_action_sound(config: Dictionary):
	AudioManager.play_player_sound(
		config.sound, 
		config.get("category", "actions"), 
		config.get("volume", 1.0)
	)

# Détecte la surface sous le joueur
static func _detect_surface(player: CharacterBody3D) -> String:
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + Vector3.DOWN * 2.0
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.get("collider")
		if collider and collider.has_method("get_surface_type"):
			return collider.get_surface_type()
		
		# Groupes de surfaces
		for surface in ["grass", "stone", "dirt", "wood"]:
			if collider and collider.is_in_group(surface + "_surface"):
				return surface
	
	return "wood"  # Défaut
