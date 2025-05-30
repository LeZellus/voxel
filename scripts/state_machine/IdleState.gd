# IdleState.gd - VERSION REFACTORISÉE
extends State  # Garde State car idle est différent des mouvements
class_name IdleState

func physics_update(delta):
	player.apply_gravity(delta)
	
	# FORCER l'arrêt immédiat
	player.velocity.x = 0 
	player.velocity.z = 0 
	
	# Transitions vers mouvement
	if InputHelper.is_moving():
		state_machine.change_state("walking")
		return
	
	if InputHelper.should_jump() and player.is_on_floor():
		SimpleAudioHelper.play_action_sound("jump")
		state_machine.change_state("jumping")
		return
	
	# Arrêter le mouvement
	player.apply_movement(Vector3.ZERO, 0, delta)
	player.move_and_slide()

func handle_input(_event):
	# Les inputs caméra sont gérés par PlayerController
	pass
	
func enter():
	# Arrêter tous les effets de mouvement
	if player.get_node_or_null("DustEffects/DustParticles"):
		player.get_node("DustEffects/DustParticles").emitting = false
	
	AudioManager.stop_footsteps()
