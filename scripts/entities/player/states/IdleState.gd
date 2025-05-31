# IdleState.gd - VERSION SIMPLE QUI FONCTIONNE
extends State
class_name IdleState

func enter():
	# Arrêter l'audio immédiatement
	player.stop_footsteps()
	
	# Arrêter les effets
	var particles = player.get_node_or_null("DustEffects/DustParticles")
	if particles:
		particles.emitting = false
	
	# Vérifier input au démarrage
	if InputHelper.is_moving():
		state_machine.change_state("walking")
		return
	
	call_deferred("_start_idle_animation")

func _start_idle_animation():
	await get_tree().process_frame
	
	# Double vérification
	if InputHelper.is_moving():
		state_machine.change_state("walking")
		return
	
	# Lancer l'animation idle
	if player.animation_player:
		player.animation_player.play("Idle")
		player.animation_player.speed_scale = 1.0

func exit():
	pass

func physics_update(delta):
	# Gravité
	player.apply_gravity(delta)
	
	# FORCER l'arrêt du mouvement
	player.velocity.x = 0 
	player.velocity.z = 0 
	
	# Transitions
	if InputHelper.is_moving():
		state_machine.change_state("walking")
		return
	
	if InputHelper.should_jump() and player.is_on_floor():
		player.play_action_sound("jump")
		state_machine.change_state("jumping")
		return
	
	# Appliquer le mouvement (arrêt)
	player.move_and_slide()

func handle_input(event):
	# Gestion caméra déjà dans PlayerController
	pass
