extends Node

var ui_manager: UIAudioManager
var player_manager: PlayerAudioManager

func _ready():
	ui_manager = UIAudioManager.new()
	player_manager = PlayerAudioManager.new()
	
	add_child(ui_manager)
	add_child(player_manager)

# Interface UI
func play_ui_sound(sound_name: String, volume: float = 1.0):
	ui_manager.play_sound(sound_name, volume)

# Interface Player
func play_player_sound(sound_name: String, category: String = "actions", volume: float = 1.0):
	player_manager.play_sound(sound_name, category, volume)

func start_footsteps(speed: float, surface: String = "grass", anim_player: AnimationPlayer = null):
	player_manager.start_footsteps(speed, surface, anim_player)

func stop_footsteps():
	player_manager.stop_footsteps()

func update_footsteps():
	player_manager.update_footsteps()

func set_footstep_positions(positions: Array):
	player_manager.set_footstep_positions(positions)

func set_footstep_tolerance(tolerance: float):
	player_manager.set_position_tolerance(tolerance)

# Contrôles de volume
func set_volume(category: String, volume: float):
	AudioConfigManager.set_volume_for_category(category, volume)

func get_volume(category: String) -> float:
	return AudioConfigManager.get_volume_for_category(category)

func set_footstep_volume(volume: float):
	set_volume("footsteps", volume)

func set_action_volume(volume: float):
	set_volume("actions", volume)

func set_ui_volume(volume: float):
	set_volume("ui", volume)

func set_global_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
