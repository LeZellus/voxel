# UIAudioManager.gd
extends Node

@onready var audio_player = AudioStreamPlayer.new()
var sounds = {}
var audio_players = {}

func _ready():
	add_child(audio_player)
	load_ui_sounds()
	setup_audio_players()

func setup_audio_players():
	create_audio_player("ui", "SFX", 1.0)
	create_audio_player("hover", "SFX", 0.1)
	create_audio_player("action", "SFX", 1.0)

func create_audio_player(name: String, bus: String, volume: float):
	var player = AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	add_child(player)
	audio_players[name] = player

func load_ui_sounds():
	var dir = DirAccess.open("res://audio/sfx/ui_interface/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
				var sound_name = file_name.get_basename()
				var full_path = "res://audio/sfx/ui_interface/" + file_name
				sounds[sound_name] = load(full_path)
			file_name = dir.get_next()

func has_sound(sound_name: String) -> bool:
	return sounds.has(sound_name)

func play_sound(sound_name: String, player_type: String = "ui"):
	if not sounds.has(sound_name):
		return
	
	var player = audio_player
	if audio_players.has(player_type):
		player = audio_players[player_type]
	
	if player.playing and player_type != "ui":
		player.stop()
	
	player.stream = sounds[sound_name]
	player.play()
