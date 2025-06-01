# scripts/config/inventory/slot/SlotErrorDisplay.gd - VERSION CORRIGÉE
class_name SlotErrorDisplay
extends SlotVisualDisplay

var error_timer: Timer
var original_positions: Array[Vector2] = []

func _init(parent: Control):
	super(parent, SlotVisualConfig.ERROR)
	_create_error_timer()
	_save_original_positions()

func _create_error_timer():
	error_timer = Timer.new()
	error_timer.wait_time = 0.8
	error_timer.one_shot = true
	error_timer.timeout.connect(hide)
	parent_control.add_child(error_timer)

func _save_original_positions():
	var size = parent_control.size
	original_positions = [
		Vector2.ZERO,           # Top-left
		Vector2(size.x, 0),     # Top-right  
		Vector2(0, size.y),     # Bottom-left
		Vector2(size.x, size.y) # Bottom-right
	]

func show():
	super.show()
	
	# CORRECTION: Toujours nettoyer et recréer le tween
	_cleanup_tween()
	_create_shake_animation()
	error_timer.start()

func hide():
	_cleanup_tween()  # CORRECTION: Nettoyer avant de cacher
	_reset_positions()
	super.hide()

func _cleanup_tween():
	"""NOUVEAU: Nettoyage sécurisé du tween"""
	if animation_tween and is_instance_valid(animation_tween):
		animation_tween.kill()
	animation_tween = null

func _create_shake_animation():
	"""NOUVEAU: Création sécurisée du tween"""
	# S'assurer que le parent_control existe et est valide
	if not parent_control or not is_instance_valid(parent_control):
		print("❌ Parent control invalide pour shake animation")
		return
	
	# Créer un nouveau tween
	animation_tween = parent_control.create_tween()
	if not animation_tween:
		print("❌ Impossible de créer le tween")
		return
	
	# CORRECTION: Vérifier que le tween est valide avant d'ajouter des propriétés
	if not is_instance_valid(animation_tween):
		print("❌ Tween créé mais invalide")
		return
	
	# Configuration du tween
	animation_tween.set_parallel(true)
	
	# CORRECTION: Vérification avant chaque appel de méthode
	var tween_method = animation_tween.tween_method(_shake_effect, 0.0, 1.0, 0.3)
	if tween_method:
		tween_method.set_ease(Tween.EASE_OUT)

func _shake_effect(progress: float):
	"""OPTIMISÉ: Effet de shake sécurisé"""
	# CORRECTION: Vérifications de sécurité
	if not parent_control or not is_instance_valid(parent_control):
		return
	
	if original_positions.is_empty():
		return
	
	var intensity = 3.0 * (1.0 - progress)
	var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	
	# CORRECTION: Vérifier chaque corner avant manipulation
	for i in range(min(corners.size(), original_positions.size())):
		if corners[i] and is_instance_valid(corners[i]):
			corners[i].position = original_positions[i] + offset
	
	# CORRECTION: Vérifier le background
	if background and is_instance_valid(background):
		background.position = Vector2.ZERO + offset
	
	# CORRECTION: Reset à la fin de l'animation
	if progress >= 0.99:
		call_deferred("_reset_positions")

func _reset_positions():
	"""OPTIMISÉ: Reset sécurisé des positions"""
	if original_positions.is_empty():
		return
	
	# Reset des corners
	for i in range(min(corners.size(), original_positions.size())):
		if corners[i] and is_instance_valid(corners[i]):
			corners[i].position = original_positions[i]
	
	# Reset du background
	if background and is_instance_valid(background):
		background.position = Vector2.ZERO

func cleanup():
	"""AMÉLIORÉ: Nettoyage complet"""
	_cleanup_tween()
	
	if error_timer and is_instance_valid(error_timer):
		error_timer.queue_free()
	error_timer = null
	
	super.cleanup()
