extends Node

var ui_manager: UIAudioManager
var player_manager: PlayerAudioManager
var environment_manager: EnvironmentAudioManager

func _ready():
	ui_manager = UIAudioManager.new()
	player_manager = PlayerAudioManager.new()
	environment_manager = EnvironmentAudioManager.new()
	
	add_child(ui_manager)
	add_child(player_manager)
	add_child(environment_manager)

# ===== INTERFACE UNIFIÉE =====

# Sons UI
func play_ui_sound(sound_name: String, volume: float = 1.0):
	ui_manager.play_sound(sound_name, volume)

# Sons joueur - avec catégorie
func play_player_sound(sound_name: String, category: String = "actions", volume: float = 1.0):
	player_manager.play_sound(sound_name, category, volume)

# Sons de pas
func start_footsteps(speed: float, surface: String = "grass"):
	player_manager.start_footsteps(speed, surface)

func stop_footsteps():
	player_manager.stop_footsteps()

# ===== CONTRÔLE DE VOLUME UNIVERSEL =====
func set_volume(category: String, volume: float):
	AudioConfigManager.set_volume_for_category(category, volume)

func get_volume(category: String) -> float:
	return AudioConfigManager.get_volume_for_category(category)

# Méthodes raccourcies pour les catégories courantes
func set_footstep_volume(volume: float):
	set_volume("footsteps", volume)

func set_action_volume(volume: float):
	set_volume("actions", volume)

func set_ui_volume(volume: float):
	set_volume("ui", volume)
