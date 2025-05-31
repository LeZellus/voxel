extends Node
class_name PlayerAudioManager

# Configuration
const FOOTSTEP_POSITIONS = [0.3, 1.1]
const POSITION_TOLERANCE = 0.05
const VOLUME_RANGE = Vector2(0.9, 1.1)
const PITCH_RANGE = Vector2(0.98, 1.02)
const RESET_THRESHOLD = 0.1

# Variables d'état
var sounds = {}
var audio_players = {}
var is_walking = false
var current_surface = "grass"
var animation_player: AnimationPlayer
var last_played_positions = []
var last_step_sound = ""

func _ready():
	add_to_group("audio_managers")
	_setup_players()
	sounds = AudioUtils.load_sounds_from_directory("res://audio/sfx/player/")

func _setup_players():
	for category in ["footsteps", "actions", "voice"]:
		var player = AudioStreamPlayer.new()
		player.bus = AudioConfigManager.get_bus_for_category(category)
		player.volume_db = linear_to_db(AudioConfigManager.get_volume_for_category(category))
		add_child(player)
		audio_players[category] = player

func play_sound(sound_name: String, category: String = "actions", volume: float = 1.0):
	var player = audio_players.get(category)
	var sound = sounds.get(sound_name)
	
	if not player or not sound:
		return
	
	var final_volume = AudioConfigManager.get_volume_for_category(category) * volume
	if final_volume <= 0.001:
		return
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sound
	player.play()

func start_footsteps(_speed: float, surface: String = "grass", anim_player: AnimationPlayer = null):
	current_surface = surface
	is_walking = true
	animation_player = anim_player
	last_played_positions.clear()

func stop_footsteps():
	is_walking = false
	animation_player = null
	last_played_positions.clear()

func update_footsteps():
	if not _can_play_footsteps():
		return
	
	var pos = animation_player.current_animation_position
	
	for i in FOOTSTEP_POSITIONS.size():
		if _should_play_step(pos, i):
			_play_footstep(i)

func _can_play_footsteps() -> bool:
	return is_walking and animation_player and animation_player.is_playing() and animation_player.current_animation != ""

func _should_play_step(current_pos: float, step_index: int) -> bool:
	var target_pos = FOOTSTEP_POSITIONS[step_index]
	var key = "pos_" + str(step_index)
	
	if abs(current_pos - target_pos) <= POSITION_TOLERANCE:
		if not last_played_positions.has(key):
			last_played_positions.append(key)
			return true
	
	# Reset si animation redémarre
	if current_pos < RESET_THRESHOLD:
		last_played_positions.clear()
	
	return false

func _play_footstep(_step_index: int):
	var sound_name = AudioUtils.select_footstep_sound(sounds, current_surface, last_step_sound)
	if sound_name == "":
		return
	
	last_step_sound = sound_name
	
	var player = audio_players["footsteps"]
	var base_volume = AudioConfigManager.get_volume_for_category("footsteps")
	var volume_var = randf_range(VOLUME_RANGE.x, VOLUME_RANGE.y)
	var pitch_var = randf_range(PITCH_RANGE.x, PITCH_RANGE.y)
	
	player.volume_db = linear_to_db(base_volume * volume_var)
	player.pitch_scale = pitch_var
	player.stream = sounds[sound_name]
	player.play()

func set_footstep_positions(_positions: Array):
	# Utilise une constante modifiable si nécessaire
	pass

func set_position_tolerance(_tolerance: float):
	# Utilise une constante modifiable si nécessaire
	pass

func _on_volume_changed(category: String, new_volume: float):
	if category in audio_players:
		audio_players[category].volume_db = linear_to_db(new_volume)
