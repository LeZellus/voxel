# UIAudioManager.gd
extends Node
@onready var audio_player = AudioStreamPlayer.new()

var sounds = {}
var audio_players = {}

func _ready():
	load_ui_sounds()
	setup_audio_players()
	print("UIAudioManager prêt, sons chargés : ", sounds.keys())
	
func setup_audio_players():
	# Créer différents players pour différents types de sons
	create_audio_player("ui", "SFX", 0.4)      # Sons d'interface
	create_audio_player("hover", "SFX", 0.1)   # Sons de survol (plus discrets)
	create_audio_player("action", "SFX", 0.6)  # Sons d'actions importantes

func create_audio_player(name: String, bus: String, volume: float):
	var player = AudioStreamPlayer.new()
	player.bus = bus
	player.volume_db = linear_to_db(volume)
	add_child(player)
	audio_players[name] = player

func load_ui_sounds():
	print("Chargement des sons depuis : res://audio/sfx/ui_interface/")
	var dir = DirAccess.open("res://audio/sfx/ui_interface/")
	if dir:
		print("Dossier trouvé, lecture des fichiers...")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Fichier trouvé : ", file_name)
			if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
				var sound_name = file_name.get_basename()
				var full_path = "res://audio/sfx/ui_interface/" + file_name
				print("Chargement du son : ", sound_name, " depuis ", full_path)
				sounds[sound_name] = load(full_path)
				if sounds[sound_name]:
					print("✓ Son chargé avec succès : ", sound_name)
				else:
					print("✗ Échec du chargement : ", sound_name)
			file_name = dir.get_next()
	else:
		print("ERREUR : Impossible d'ouvrir le dossier res://audio/sfx/ui_interface/")

func play_sound(sound_name: String, player_type: String = "ui"):
	if not sounds.has(sound_name):
		print("Son non trouvé : ", sound_name)
		return
	
	if not audio_players.has(player_type):
		print("Player non trouvé : ", player_type)
		return
	
	var player = audio_players[player_type]
	player.stream = sounds[sound_name]
	player.play()
