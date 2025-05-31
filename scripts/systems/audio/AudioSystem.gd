# scripts/systems/audio/AudioSystem.gd - VERSION UNIFIÉE
extends Node
class_name AudioSystem

# === CONFIGURATION AUDIO ===
const AUDIO_CONFIG = {
	"master": {"volume": 1.0, "bus": "Master"},
	"sfx": {"volume": 1.0, "bus": "SFX"},
	"music": {"volume": 0.8, "bus": "Music"},
	"voice": {"volume": 0.9, "bus": "Voice"},
	"ambience": {"volume": 0.7, "bus": "Ambience"}
}

# === CANAUX AUDIO (remplace les 3 managers séparés) ===
var channels: Dictionary = {}
var sounds_cache: Dictionary = {}

# === FOOTSTEPS (simplifié) ===
var footstep_state = {
	"is_active": false,
	"current_surface": "grass",
	"animation_player": null,
	"last_positions": [],
	"last_sound": ""
}

func _ready():
	print("🎵 AudioSystem unifié")
	_setup_channels()
	_load_all_sounds()
	add_to_group("audio_system")

# === SETUP ===
func _setup_channels():
	"""Crée les canaux audio (remplace les managers séparés)"""
	for category in AUDIO_CONFIG.keys():
		if category == "master":
			continue
			
		var player = AudioStreamPlayer.new()
		player.bus = AUDIO_CONFIG[category].bus
		player.volume_db = linear_to_db(AUDIO_CONFIG[category].volume)
		add_child(player)
		channels[category] = player
	
	print("✅ %d canaux audio créés" % channels.size())

func _load_all_sounds():
	"""Charge tous les sons en une fois (cache unifié)"""
	var paths = {
		"ui": "res://audio/sfx/ui_interface/",
		"player": "res://audio/sfx/player/",
		"environment": "res://audio/sfx/environment/"
	}
	
	for category in paths:
		sounds_cache[category] = AudioUtils.load_sounds_from_directory(paths[category])
		print("📁 Sons %s chargés: %d" % [category, sounds_cache[category].size()])

# === API PUBLIQUE SIMPLIFIÉE ===

func play_ui_sound(sound_name: String, volume: float = 1.0):
	"""Joue un son d'interface"""
	_play_sound("ui", sound_name, volume)

func play_player_sound(sound_name: String, volume: float = 1.0):
	"""Joue un son de joueur (signature simple)"""
	_play_sound("player", sound_name, volume)

func play_player_sound_with_category(sound_name: String, category: String = "actions", volume: float = 1.0):
	"""Joue un son de joueur avec catégorie (pour compatibilité)"""
	# Ignore la catégorie pour l'instant, utilise toujours "player"
	_play_sound("player", sound_name, volume)

func play_environment_sound(sound_name: String, volume: float = 1.0):
	"""Joue un son d'environnement"""
	_play_sound("environment", sound_name, volume)

# === FOOTSTEPS COMPATIBLE AVEC L'ANCIEN SYSTÈME ===

func start_footsteps(speed: float, surface: String = "grass", anim_player: AnimationPlayer = null):
	"""Démarre les sons de pas (compatible avec l'ancien système)"""
	footstep_state.is_active = true
	footstep_state.current_surface = surface
	footstep_state.animation_player = anim_player
	footstep_state.last_positions.clear()
	print("🦶 Footsteps démarrés: surface=%s, speed=%.1f" % [surface, speed])

func stop_footsteps():
	"""Arrête les sons de pas"""
	footstep_state.is_active = false
	footstep_state.animation_player = null
	print("🛑 Footsteps arrêtés")

func update_footsteps():
	"""Met à jour les footsteps (appelé depuis le player)"""
	if not footstep_state.is_active or not footstep_state.animation_player:
		return
	
	var anim = footstep_state.animation_player
	if not anim.is_playing():
		return
	
	var pos = anim.current_animation_position
	var positions = [0.3, 1.0]  # Positions de pas dans l'animation
	
	for i in positions.size():
		var target_pos = positions[i]
		var key = "step_%d" % i
		
		if abs(pos - target_pos) <= 0.05:  # Tolérance
			if not footstep_state.last_positions.has(key):
				_play_footstep()
				footstep_state.last_positions.append(key)
	
	# Reset si animation recommence
	if pos < 0.1:
		footstep_state.last_positions.clear()

# === CONTRÔLES VOLUME ===

func set_volume(category: String, volume: float):
	"""Change le volume d'une catégorie"""
	volume = clamp(volume, 0.0, 2.0)
	
	if category in AUDIO_CONFIG:
		AUDIO_CONFIG[category].volume = volume
		
		if category in channels:
			channels[category].volume_db = linear_to_db(volume)
		
		print("🔊 Volume %s: %.2f" % [category, volume])

func get_volume(category: String) -> float:
	"""Récupère le volume d'une catégorie"""
	return AUDIO_CONFIG.get(category, {}).get("volume", 1.0)

# === MÉTHODES INTERNES ===

func _play_sound(category: String, sound_name: String, volume: float):
	"""Méthode interne unifiée pour jouer un son"""
	if not channels.has(category):
		print("❌ Canal audio introuvable: %s" % category)
		return
	
	if not sounds_cache.has(category) or not sounds_cache[category].has(sound_name):
		print("❌ Son introuvable: %s/%s" % [category, sound_name])
		return
	
	var player = channels[category]
	var base_volume = get_volume(category)
	var final_volume = base_volume * volume
	
	if final_volume <= 0.001:
		return
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sounds_cache[category][sound_name]
	player.play()

func _play_footstep():
	"""Joue un son de pas"""
	var sound_name = AudioUtils.select_footstep_sound(
		sounds_cache.get("player", {}), 
		footstep_state.current_surface, 
		footstep_state.last_sound
	)
	
	if sound_name == "":
		return
	
	footstep_state.last_sound = sound_name
	
	# Variation aléatoire
	var volume_var = randf_range(0.9, 1.1)
	var pitch_var = randf_range(0.98, 1.02)
	
	var player = channels.get("sfx")
	if player:
		player.volume_db = linear_to_db(get_volume("sfx") * volume_var)
		player.pitch_scale = pitch_var
		player.stream = sounds_cache["player"][sound_name]
		player.play()

# === ALIAS POUR COMPATIBILITÉ ===
func play_sound(sound_name: String, category: String = "sfx", volume: float = 1.0):
	"""Alias pour compatibilité avec l'ancien système"""
	match category:
		"ui": play_ui_sound(sound_name, volume)
		"actions": play_player_sound(sound_name, volume)
		"environment": play_environment_sound(sound_name, volume)
		_: _play_sound("sfx", sound_name, volume)
