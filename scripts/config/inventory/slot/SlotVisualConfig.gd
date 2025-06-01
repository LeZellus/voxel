# scripts/config/inventory/slot/SlotVisualConfig.gd - VERSION CENTRALISÉE
class_name SlotVisualConfig
extends RefCounted

# === CONFIGURATIONS DES ÉTATS ===

const HOVER = {
	"corner_color": Color("#a8b5b2"),
	"background_color": Color.TRANSPARENT,
	"background_alpha": 0.0,
	"size_ratio": 0.20,
	"z_index": 50
}

const SELECTED = {
	"corner_color": Color("#a8ca58"),
	"background_color": Color("#a8ca58"),
	"background_alpha": 0.15,
	"size_ratio": 0.4,
	"z_index": 51
}

const ERROR = {
	"corner_color": Color("#e74c3c"),
	"background_color": Color("#a53030"),
	"background_alpha": 0.08,
	"size_ratio": 0.30,
	"z_index": 52
}

# === ANIMATIONS ===
const TIMING = {
	"fade_duration": 0.15,
	"corner_grow_duration": 0.2,
	"shake_duration": 0.4,
	"error_display_time": 1.0
}

const EFFECTS = {
	"shake_intensity": 3.0,
	"corner_thickness": 2
}

# === UTILITAIRES ===

static func get_config_for_state(state_name: String) -> Dictionary:
	"""Récupère la config pour un état donné"""
	match state_name.to_lower():
		"hover": return HOVER
		"selected": return SELECTED
		"error": return ERROR
		_: return {}

static func get_timing(key: String) -> float:
	"""Récupère un timing"""
	return TIMING.get(key, 0.2)

static func get_effect_value(key: String) -> float:
	"""Récupère une valeur d'effet"""
	return EFFECTS.get(key, 1.0)
