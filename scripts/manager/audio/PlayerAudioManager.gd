extends Node
class_name PlayerAudioManager

var sounds = {}
var audio_players = {}

# Timer pour les pas
var footstep_timer: Timer
var is_walking = false
var current_surface = "grass"
var current_speed = 0.0

func _ready():
	# S'enregistrer dans le groupe pour recevoir les notifications de volume
	add_to_group("audio_managers")
	
	setup_audio_players()
	setup_footstep_timer()
	load_player_sounds()

func setup_audio_players():
	# Créer les players selon la configuration
	create_audio_player("footsteps")
	create_audio_player("actions") 
	create_audio_player("voice")

func create_audio_player(category: String):
	var player = AudioStreamPlayer.new()
	player.bus = AudioConfigManager.get_bus_for_category(category)
	player.volume_db = linear_to_db(AudioConfigManager.get_volume_for_category(category))
	add_child(player)
	audio_players[category] = player

func setup_footstep_timer():
	footstep_timer = Timer.new()
	footstep_timer.timeout.connect(_play_footstep)
	add_child(footstep_timer)

func load_player_sounds():
	var dir = DirAccess.open("res://audio/sfx/player/")
	if not dir:
		print("Dossier player audio non trouvé")
		return
		
	load_sounds_recursive(dir, "res://audio/sfx/player/")
	print("Sons joueur chargés: ", sounds.size(), " fichiers")

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

# 🔥 MÉTHODE UNIVERSELLE pour jouer n'importe quel son
func play_sound(sound_name: String, category: String = "actions", volume_multiplier: float = 1.0):
	if not sounds.has(sound_name):
		print("Son non trouvé: ", sound_name)
		return
	
	# Obtenir le player pour cette catégorie
	var player = audio_players.get(category)
	if not player:
		print("Catégorie audio non trouvée: ", category)
		return
	
	# Calculer le volume final
	var base_volume = AudioConfigManager.get_volume_for_category(category)
	var final_volume = base_volume * volume_multiplier
	
	if final_volume <= 0.001:
		return  # Volume trop bas
	
	player.volume_db = linear_to_db(final_volume)
	player.stream = sounds[sound_name]
	player.play()

# Sons de pas automatiques (inchangé mais simplifié)
func start_footsteps(speed: float, surface: String = "grass"):
	if is_walking and abs(speed - current_speed) < 0.1 and surface == current_surface:
		return
	
	current_surface = surface
	current_speed = speed
	is_walking = true
	
	var interval = 0.5 / (speed / 5.0)
	interval = clamp(interval, 0.25, 0.8)
	
	footstep_timer.stop()
	footstep_timer.wait_time = interval
	footstep_timer.start()

func stop_footsteps():
	is_walking = false
	current_speed = 0.0
	footstep_timer.stop()
	if audio_players.has("footsteps") and audio_players["footsteps"].playing:
		audio_players["footsteps"].stop()

func _play_footstep():
	if not is_walking:
		return
	
	var footstep_sounds = []
	for sound_name in sounds.keys():
		if sound_name.contains("step") or sound_name.contains("footstep"):
			if sound_name.contains(current_surface):
				footstep_sounds.append(sound_name)
	
	if footstep_sounds.is_empty():
		for sound_name in sounds.keys():
			if sound_name.contains("step"):
				footstep_sounds.append(sound_name)
	
	if footstep_sounds.size() > 0:
		var random_sound = footstep_sounds[randi() % footstep_sounds.size()]
		var volume_variation = randf_range(0.8, 1.2)
		play_sound(random_sound, "footsteps", volume_variation)

# 🔥 CALLBACK automatique quand le volume change
func _on_volume_changed(category: String, new_volume: float):
	if category in audio_players:
		audio_players[category].volume_db = linear_to_db(new_volume)
		print("Volume ", category, " mis à jour: ", new_volume)
