extends Node

var audio_settings = {
	"master": 1.0,
	"sfx": 1.0,
	"music": 0.8,
	"voice": 0.9,
	"ambience": 0.7,
	"footsteps": 0.7,
	"actions": 0.8,
	"ui": 1.0,
	"environment": 0.6
}

var sound_categories = {
	"footsteps": {"bus": "SFX", "base_volume": 0.7},
	"actions": {"bus": "SFX", "base_volume": 0.8},
	"voice": {"bus": "Voice", "base_volume": 0.9},
	"ui": {"bus": "SFX", "base_volume": 1.0},
	"environment": {"bus": "SFX", "base_volume": 0.6},
	"ambience": {"bus": "Ambience", "base_volume": 0.7}
}

func get_volume_for_category(category: String) -> float:
	if category in audio_settings:
		return audio_settings[category]
	return 1.0

func set_volume_for_category(category: String, volume: float):
	audio_settings[category] = clamp(volume, 0.0, 2.0)
	get_tree().call_group("audio_managers", "_on_volume_changed", category, volume)

func get_bus_for_category(category: String) -> String:
	if category in sound_categories:
		return sound_categories[category]["bus"]
	return "SFX"
