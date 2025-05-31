# ===================================
# EnvironmentAudioManager.gd - Sons de l'environnement
extends Node
class_name EnvironmentAudioManager

var sounds = {}
var audio_players_3d = []
var audio_players_2d = []

func _ready():
	load_environment_sounds()
	setup_audio_players()

func setup_audio_players():
	# Créer plusieurs AudioStreamPlayer3D pour les sons spatialisés
	for i in range(10):
		var player_3d = AudioStreamPlayer3D.new()
		player_3d.bus = "SFX"
		add_child(player_3d)
		audio_players_3d.append(player_3d)
	
	# Créer quelques AudioStreamPlayer pour les ambiances
	for i in range(5):
		var player_2d = AudioStreamPlayer.new()
		player_2d.bus = "Ambience"
		add_child(player_2d)
		audio_players_2d.append(player_2d)

func load_environment_sounds():
	load_sounds_from_directory("res://audio/sfx/environment/")

func load_sounds_from_directory(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
			var sound_name = file_name.get_basename()
			var full_path = path + file_name
			sounds[sound_name] = load(full_path)
		file_name = dir.get_next()

func play_sound(sound_name: String, position: Vector3 = Vector3.ZERO):
	if not sounds.has(sound_name):
		return
	
	var player = get_available_3d_player()
	if player:
		player.stream = sounds[sound_name]
		player.global_position = position
		player.play()

func get_available_3d_player() -> AudioStreamPlayer3D:
	for player in audio_players_3d:
		if not player.playing:
			return player
	# Si tous sont occupés, prendre le premier
	return audio_players_3d[0]

func play_ambience(sound_name: String, loop: bool = true):
	if not sounds.has(sound_name):
		return
	
	var player = get_available_2d_player()
	if player:
		player.stream = sounds[sound_name]
		if player.stream is AudioStreamOggVorbis:
			player.stream.loop = loop
		player.play()

func get_available_2d_player() -> AudioStreamPlayer:
	for player in audio_players_2d:
		if not player.playing:
			return player
	return audio_players_2d[0]
