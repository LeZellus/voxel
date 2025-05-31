class_name SimpleAudioHelper

# Sons d'action simples
static var ACTION_SOUNDS = {
	"jump": "jump",
	"land": "land", 
	"pickup": "pickup"
}

# SIMPLIFIÉ - Plus besoin de STATE_SOUNDS complexes
static func play_action_sound(action: String, volume: float = 1.0):
	var sound_name = ACTION_SOUNDS.get(action)
	if not sound_name:
		print("⚠️ Son d'action introuvable: " + action)
		return
	
	AudioSystem.play_player_sound(sound_name, volume)

# Alias directs pour AudioSystem
static func start_footsteps(anim_player: AnimationPlayer, surface: String = "grass"):
	AudioSystem.start_footsteps(anim_player, surface)

static func stop_footsteps():
	AudioSystem.stop_footsteps()

static func update_footsteps():
	AudioSystem.update_footsteps()
