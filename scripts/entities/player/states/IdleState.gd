# IdleState.gd - VERSION CORRIGÉE (vérification input au démarrage)
extends State
class_name IdleState

func enter():
	print("Mode idle activé")
	
	# AJOUT : Vérifier immédiatement si on doit bouger
	if InputHelper.is_moving():
		print("🚀 Input détecté au démarrage - passage direct en walking")
		state_machine.change_state("walking")
		return
	
	# Arrêter tous les effets de mouvement
	if player.get_node_or_null("DustEffects/DustParticles"):
		player.get_node("DustEffects/DustParticles").emitting = false
	
	player.stop_footsteps()
	
	# Lancer l'animation idle avec délai pour l'initialisation
	call_deferred("_start_idle_animation")

func _start_idle_animation():
	# Attendre que tout soit prêt
	await get_tree().process_frame
	
	# AJOUT : Double vérification avant de lancer l'animation
	if InputHelper.is_moving():
		print("🚀 Input détecté pendant l'initialisation - annulation animation idle")
		state_machine.change_state("walking")
		return
	
	if player and player.animation_player:
		player.animation_player.play("Idle")
		player.animation_player.speed_scale = 1.0
		print("✅ Animation Idle lancée")
	else:
		print("❌ AnimationPlayer non trouvé pour l'animation Idle")

func exit():
	# Arrêter l'animation idle
	if player.animation_player:
		player.animation_player.stop()
		print("🛑 Animation Idle arrêtée")

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
