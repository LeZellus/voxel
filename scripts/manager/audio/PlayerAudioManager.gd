extends Node
class_name PlayerAudioManager

var sounds = {}
var audio_players = {}

var is_walking = false
var current_surface = "grass"
var current_speed = 0.0

# 🎬 POSITIONS EXACTES EN SECONDES (depuis votre AnimationPlayer)
var footstep_positions = [0.2, 1.1]  # Positions exactes de vos pas !
var position_tolerance = 0.05  # Tolérance de détection (50ms)
var last_played_positions = []
var animation_player: AnimationPlayer

var last_step_sound = ""
var debug_enabled = true

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

func play_sound(sound_name: String, category: String = "actions", volume_multiplier: float = 1.0):
	if not sounds.has(sound_name):
		print("Son non trouvé: ", sound_name)
		return
	
	var player = audio_players.get(category)
	if not player:
		print("Catégorie audio non trouvée: ", category)
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
	
	if debug_enabled:
		print("=== FOOTSTEPS DÉMARRÉS (POSITIONS) ===")
		print("Positions cibles: ", footstep_positions, "s")
		print("Tolérance: ±", position_tolerance, "s")
		print("======================================")

func stop_footsteps():
	is_walking = false
	current_speed = 0.0
	animation_player = null
	last_played_positions.clear()
	
	if debug_enabled:
		print("🛑 FOOTSTEPS ARRÊTÉS")

# 🎬 MÉTHODE ULTRA-SIMPLE : Comparaison directe des positions
func update_footsteps():
	if not is_walking or not animation_player:
		return
	
	if not animation_player.is_playing():
		return
	
	var current_animation = animation_player.current_animation
	if current_animation == "":
		return
	
	# 🔥 POSITION ACTUELLE EN SECONDES
	var animation_position = animation_player.current_animation_position
	var animation_length = animation_player.get_animation(current_animation).length
	
	if debug_enabled:
		print("🎬 Position actuelle: ", snappedf(animation_position, 0.01), "s")
	
	# 🎯 VÉRIFIER CHAQUE POSITION DE PAS
	for i in range(footstep_positions.size()):
		var target_position = footstep_positions[i]
		
		# 🔥 DÉTECTION AVEC TOLÉRANCE
		var distance = abs(animation_position - target_position)
		
		if debug_enabled:
			print("  Distance à position ", target_position, "s: ", snappedf(distance, 0.01), "s")
		
		if distance <= position_tolerance:
			var position_key = "pos_" + str(i)
			if not last_played_positions.has(position_key):
				if debug_enabled:
					print("🎵 PAS DÉCLENCHÉ à position ", target_position, "s !")
				
				play_footstep_at_position(target_position, i)
				last_played_positions.append(position_key)
	
	# 🔄 Reset quand l'animation redémarre
	if animation_position < 0.1:  # Premier 10% de l'animation
		if last_played_positions.size() > 0:
			if debug_enabled:
				print("🔄 Reset positions (animation redémarrée)")
			last_played_positions.clear()

func play_footstep_at_position(position: float, step_index: int):
	# Récupérer les sons disponibles
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
		if debug_enabled:
			print("❌ Aucun son trouvé")
		return
	
	# Éviter répétition
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
	
	if debug_enabled:
		print("🔊 SON JOUÉ: ", selected_sound, " (pas ", step_index + 1, ")")

# 🔧 MÉTHODES DE CONFIGURATION
func set_footstep_positions(positions: Array):
	footstep_positions = positions
	last_played_positions.clear()
	print("🎬 Nouvelles positions: ", positions, "s")

func set_position_tolerance(tolerance: float):
	position_tolerance = tolerance
	print("🎯 Nouvelle tolérance: ±", tolerance, "s")

func set_debug_enabled(enabled: bool):
	debug_enabled = enabled

func _on_volume_changed(category: String, new_volume: float):
	if category in audio_players:
		audio_players[category].volume_db = linear_to_db(new_volume)
