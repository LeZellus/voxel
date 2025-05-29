extends Node
class_name UIAudioManager

var sounds = {}
var audio_players = {}

func _ready():
	add_to_group("audio_managers")
	setup_audio_players()
	load_ui_sounds()

func setup_audio_players():
	# Un seul player pour l'UI
	create_audio_player("ui")

func create_audio_player(category: String):
	var player = AudioStreamPlayer.new()
	player.bus = AudioConfigManager.get_bus_for_category(category)
	player.volume_db = linear_to_db(AudioConfigManager.get_volume_for_category(category))
	add_child(player)
	audio_players[category] = player

func load_ui_sounds():
	var dir = DirAccess.open("res://audio/sfx/ui_interface/")
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
			var sound_name = file_name.get_basename()
			sounds[sound_name] = load("res://audio/sfx/ui_interface/" + file_name)
		file_name = dir.get_next()

func play_sound(sound_name: String, volume_multiplier: float = 1.0):
	if not sounds.has(sound_name):
		return
	
	var player = audio_players["ui"]
	var base_volume = AudioConfigManager.get_volume_for_category("ui")
	var final_volume = base_volume * volume_multiplier
	
	if final_volume <= 0.001:
		return
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sounds[sound_name]
	player.play()

func _on_volume_changed(category: String, new_volume: float):
	if category == "ui" and audio_players.has("ui"):
		audio_players["ui"].volume_db = linear_to_db(new_volume)
