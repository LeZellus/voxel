# AudioSystem.gd - VERSION SIMPLIFIÉE (basée sur ton existant)
extends Node
class_name AudioSystem

# Instance singleton
static var instance: AudioSystem

# Configuration simplifiée  
const AUDIO_CONFIG = {
	"sfx": {"volume": 1.0, "bus": "SFX"},
	"music": {"volume": 0.8, "bus": "Music"},
	"voice": {"volume": 0.9, "bus": "Voice"},
	"ambience": {"volume": 0.7, "bus": "Ambience"}
}

# Canaux audio
var channels: Dictionary = {}
var sounds_cache: Dictionary = {}

# État footsteps simplifié
var footstep_state = {
	"is_active": false,
	"animation_player": null,
	"current_surface": "grass",
	"last_sound": "",
	"last_positions": [],
	"positions": [0.3, 1.0],
	"tolerance": 0.05
}

func _ready():
	# Singleton
	if instance == null:
		instance = self
		add_to_group("audio_system")
	else:
		queue_free()
		return
	
	_setup_channels()
	_load_all_sounds()

func _setup_channels():
	"""Crée les canaux audio simplifiés"""
	for category in AUDIO_CONFIG.keys():
		var player = AudioStreamPlayer.new()
		player.bus = AUDIO_CONFIG[category].bus
		player.volume_db = linear_to_db(AUDIO_CONFIG[category].volume)
		add_child(player)
		channels[category] = player

func _load_all_sounds():
	"""Charge tous les sons"""
	var paths = {
		"ui": "res://audio/sfx/ui_interface/",
		"player": "res://audio/sfx/player/",
		"environment": "res://audio/sfx/environment/"
	}
	
	for category in paths:
		sounds_cache[category] = AudioUtils.load_sounds_from_directory(paths[category])
		
		if !category:
			print("📁 Problèmes Sons : ",category)

# === API PUBLIQUE STATIC (pour compatibilité) ===

static func play_ui_sound(sound_name: String, volume: float = 1.0):
	if instance: instance._play_sound("sfx", sound_name, "ui", volume)

static func play_player_sound(sound_name: String, volume: float = 1.0):
	if instance: instance._play_sound("sfx", sound_name, "player", volume)

static func play_environment_sound(sound_name: String, volume: float = 1.0):
	if instance: instance._play_sound("sfx", sound_name, "environment", volume)

# === FOOTSTEPS SIMPLIFIÉ ===

static func start_footsteps(anim_player: AnimationPlayer, surface: String = "grass"):
	if not instance: return
	
	instance.footstep_state.is_active = true
	instance.footstep_state.animation_player = anim_player
	instance.footstep_state.current_surface = surface
	instance.footstep_state.last_positions.clear()

static func stop_footsteps():
	if not instance: return
	
	instance.footstep_state.is_active = false
	instance.footstep_state.animation_player = null

static func update_footsteps():
	if not instance: return
	instance._update_footstep_logic()

func _update_footstep_logic():
	var config = footstep_state
	
	if not config.is_active or not config.animation_player:
		return
	
	var anim = config.animation_player
	if not anim.is_playing():
		return
	
	var pos = anim.current_animation_position
	
	for i in config.positions.size():
		var target_pos = config.positions[i]
		var key = "step_%d" % i
		
		if abs(pos - target_pos) <= config.tolerance:
			if not config.last_positions.has(key):
				_play_footstep()
				config.last_positions.append(key)
	
	# Reset animation
	if pos < 0.1:
		config.last_positions.clear()

func _play_footstep():
	var config = footstep_state
	var player_sounds = sounds_cache.get("player", {})
	
	var sound_name = AudioUtils.select_footstep_sound(
		player_sounds, 
		config.current_surface, 
		config.last_sound
	)
	
	if sound_name == "":
		return
	
	config.last_sound = sound_name
	
	var player = channels.get("sfx")
	if player and player_sounds.has(sound_name):
		var volume = AUDIO_CONFIG["sfx"].volume * randf_range(0.9, 1.1)
		player.volume_db = linear_to_db(volume)
		player.pitch_scale = randf_range(0.98, 1.02)
		player.stream = player_sounds[sound_name]
		player.play()

# === MÉTHODE INTERNE ===

func _play_sound(channel: String, sound_name: String, category: String, volume: float):
	var player = channels.get(channel)
	var sounds = sounds_cache.get(category, {})
	
	if not player or not sounds.has(sound_name):
		print("❌ Son introuvable: %s/%s" % [category, sound_name])
		return
	
	var base_volume = AUDIO_CONFIG[channel].volume
	var final_volume = base_volume * volume
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sounds[sound_name]
	player.play()

# === CONTRÔLES VOLUME ===

static func set_volume(channel: String, volume: float):
	if not instance or not instance.AUDIO_CONFIG.has(channel):
		return
	
	volume = clamp(volume, 0.0, 2.0)
	instance.AUDIO_CONFIG[channel].volume = volume
	
	var player = instance.channels.get(channel)
	if player:
		player.volume_db = linear_to_db(volume)

static func get_volume(channel: String) -> float:
	if not instance or not instance.AUDIO_CONFIG.has(channel):
		return 1.0
	return instance.AUDIO_CONFIG[channel].volume
