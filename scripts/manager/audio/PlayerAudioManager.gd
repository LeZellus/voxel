extends Node
class_name PlayerAudioManager

var sounds = {}
var audio_players = {}

var is_walking = false
var current_surface = "grass"
var current_speed = 0.0

var footstep_positions = [0.3, 1.0]  # Positions des pas en secondes
var position_tolerance = 0.05        # Tolérance de détection
var last_played_positions = []
var animation_player: AnimationPlayer

var last_step_sound = ""

func _ready():
	add_to_group("audio_managers")
	setup_audio_players()
	load_player_sounds()

func setup_audio_players():
	create_audio_player("footsteps")
	create_audio_player("actions") 
	create_audio_player("voice")

func create_audio_player(category: String):
	var player = AudioStreamPlayer.new()
	player.bus = AudioConfigManager.get_bus_for_category(category)
	player.volume_db = linear_to_db(AudioConfigManager.get_volume_for_category(category))
	add_child(player)
	audio_players[category] = player

func load_player_sounds():
	var dir = DirAccess.open("res://audio/sfx/player/")
	if not dir:
		return
		
	load_sounds_recursive(dir, "res://audio/sfx/player/")

func load_sounds_recursive(dir: DirAccess, path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = path + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			var subdir = DirAccess.open(full_path)
			if subdir:
				load_sounds_recursive(subdir, full_path + "/")
		elif file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
			var sound_name = file_name.get_basename()
			sounds[sound_name] = load(full_path)
		
		file_name = dir.get_next()

func play_sound(sound_name: String, category: String = "actions", volume_multiplier: float = 1.0):
	if not sounds.has(sound_name):
		return
	
	var player = audio_players.get(category)
	if not player:
		return
	
	var base_volume = AudioConfigManager.get_volume_for_category(category)
	var final_volume = base_volume * volume_multiplier
	
	if final_volume <= 0.001:
		return
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sounds[sound_name]
	player.play()

func start_footsteps(speed: float, surface: String = "grass", anim_player: AnimationPlayer = null):
	current_surface = surface
	current_speed = speed
	is_walking = true
	animation_player = anim_player
	last_played_positions.clear()

func stop_footsteps():
	is_walking = false
	current_speed = 0.0
	animation_player = null
	last_played_positions.clear()

func update_footsteps():
	if not is_walking or not animation_player:
		return
	
	if not animation_player.is_playing():
		return
	
	var current_animation = animation_player.current_animation
	if current_animation == "":
		return
	
	var animation_position = animation_player.current_animation_position
	
	# Vérifier chaque position de pas
	for i in range(footstep_positions.size()):
		var target_position = footstep_positions[i]
		var distance = abs(animation_position - target_position)
		
		if distance <= position_tolerance:
			var position_key = "pos_" + str(i)
			if not last_played_positions.has(position_key):
				play_footstep_at_position(target_position, i)
				last_played_positions.append(position_key)
	
	# Reset quand l'animation redémarre
	if animation_position < 0.1:
		last_played_positions.clear()

func play_footstep_at_position(position: float, step_index: int):
	var footstep_sounds = []
	for sound_name in sounds.keys():
		if sound_name.contains("step") or sound_name.contains("footstep"):
			if sound_name.contains(current_surface):
				footstep_sounds.append(sound_name)
	
	if footstep_sounds.is_empty():
		for sound_name in sounds.keys():
			if sound_name.contains("step"):
				footstep_sounds.append(sound_name)
	
	if footstep_sounds.is_empty():
		return
	
	# Éviter répétition du même son
	var available_sounds = footstep_sounds.duplicate()
	if footstep_sounds.size() > 1:
		available_sounds.erase(last_step_sound)
		if available_sounds.is_empty():
			available_sounds = footstep_sounds
	
	var selected_sound = available_sounds[randi() % available_sounds.size()]
	last_step_sound = selected_sound
	
	# Variations naturelles
	var volume_variation = randf_range(0.9, 1.1)
	var pitch_variation = randf_range(0.98, 1.02)
	
	var player = audio_players["footsteps"]
	var base_volume = AudioConfigManager.get_volume_for_category("footsteps")
	var final_volume = base_volume * volume_variation
	
	player.volume_db = linear_to_db(final_volume)
	player.pitch_scale = pitch_variation
	player.stream = sounds[selected_sound]
	player.play()

func set_footstep_positions(positions: Array):
	footstep_positions = positions
	last_played_positions.clear()

func set_position_tolerance(tolerance: float):
	position_tolerance = tolerance

func _on_volume_changed(category: String, new_volume: float):
	if category in audio_players:
		audio_players[category].volume_db = linear_to_db(new_volume)
