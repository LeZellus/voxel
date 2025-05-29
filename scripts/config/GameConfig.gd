# GameConfig.gd - Configuration centralisée du jeu
class_name GameConfig
extends RefCounted

# Configuration du joueur
const PLAYER = {
	"walk_speed": 5.0,
	"run_speed": 8.0,
	"jump_velocity": 4.5,
	"rotation_speed": 12.0,
	"air_control": 0.8
}

# Configuration de la caméra
const CAMERA = {
	"mouse_sensitivity": 0.002,
	"min_vertical_angle": -PI/2,
	"max_vertical_angle": PI/4,
	"spring_length": 8.0,
	"zoom_min": 3.0,
	"zoom_max": 15.0,
	"zoom_step": 1.0
}

# Configuration de l'inventaire
const INVENTORY = {
	"size": 36,
	"grid_columns": 9,
	"slot_size": Vector2(64, 64),
	"estimated_height": 400
}

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

# Validation des configs
static func validate_config():
	assert(PLAYER.walk_speed > 0, "Vitesse de marche invalide")
	assert(INVENTORY.size > 0, "Taille d'inventaire invalide")
	assert(CAMERA.spring_length > 0, "Longueur de spring arm invalide")
	
	print("Configuration validée avec succès")

# Getters simplifiés
static func get_player_config() -> Dictionary:
	return PLAYER

static func get_audio_config(category: String) -> Dictionary:
	return AUDIO.get(category, {})

static func get_path(key: String) -> String:
	return PATHS.get(key, "")
