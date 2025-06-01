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
	
	# S'assurer que le tween existe
	if not animation_tween:
		animation_tween = parent_control.create_tween()
	
	_add_shake_effect()
	error_timer.start()

func hide():
	_reset_positions()  # S'assurer que tout est remis en place
	super.hide()
	
func _add_shake_effect():
	if not animation_tween:
		animation_tween = parent_control.create_tween()
	
	animation_tween.set_parallel(true)
	animation_tween.tween_method(_shake_effect, 0.0, 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _shake_effect(progress: float):
	var intensity = 3.0 * (1.0 - progress)
	var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	
	for i in range(corners.size()):
		if corners[i] and is_instance_valid(corners[i]):
			corners[i].position = original_positions[i] + offset
	
	if background:
		background.position = Vector2.ZERO + offset
	
	# CORRECTION: Remettre en place à la fin
	if progress >= 0.99:
		_reset_positions()

func _reset_positions():
	"""Remet les éléments à leur position originale"""
	for i in range(corners.size()):
		if corners[i] and is_instance_valid(corners[i]):
			corners[i].position = original_positions[i]
	
	if background:
		background.position = Vector2.ZERO

func cleanup():
	super.cleanup()
	if error_timer: error_timer.queue_free()
