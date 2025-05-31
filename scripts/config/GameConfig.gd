# GameConfig.gd - Configuration centralisée du jeu
class_name GameConfig
extends RefCounted

# Configuration UI
const UI = {
	"animation_duration": 0.4,
	"fade_duration": 0.2,
	"drag_threshold": 5.0
}

# Configuration audio par catégorie
const AUDIO = {
	"footsteps": {
		"volume_range": Vector2(0.9, 1.1),
		"pitch_range": Vector2(0.98, 1.02),
		"tolerance": 0.05,
		"reset_threshold": 0.1
	},
	"ui": {
		"volume": 1.0,
		"category": "ui"
	},
	"actions": {
		"volume": 0.8,
		"category": "actions"
	}
}

# Paths des ressources
const PATHS = {
	"audio_ui": "res://audio/sfx/ui_interface/",
	"audio_player": "res://audio/sfx/player/",
	"audio_environment": "res://audio/sfx/environment/",
	"icons": "res://assets/icons/",
	"ui_scenes": "res://scenes/ui/"
}

# Groupes de physique
const GROUPS = {
	"player": "player",
	"audio_managers": "audio_managers",
	"surfaces": {
		"grass": "grass_surface",
		"stone": "stone_surface", 
		"dirt": "dirt_surface",
		"wood": "wood_surface"
	}
}

static func get_audio_config(category: String) -> Dictionary:
	return AUDIO.get(category, {})

static func get_path(key: String) -> String:
	return PATHS.get(key, "")
