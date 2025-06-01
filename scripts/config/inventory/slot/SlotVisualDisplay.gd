class_name SlotVisualDisplay
extends RefCounted

var parent_control: Control
var config: Dictionary
var corners: Array[Control] = []
var background: ColorRect
var animation_tween: Tween
var is_visible: bool = false
var is_mouse_over: bool = false

# Propriétés pour l'animation
var current_corner_size: float = 0.0
var target_corner_size: float = 0.0
var animation_duration: float = 0.15

func _init(parent: Control, display_config: Dictionary):
	parent_control = parent
	config = display_config
	target_corner_size = config.size_ratio
	_create_visuals()

func _create_visuals():
	_create_background()
	_create_corners()

func _create_background():
	background = ColorRect.new()
	background.color = config.background_color
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.size = parent_control.size
	background.modulate.a = 0.0
	background.z_index = config.z_index
	parent_control.add_child(background)

func _create_corners():
	for i in range(4):
		var corner = SlotCornerFactory.create_corner(config.corner_color, 0.0)  # Commencer à 0
		corner.visible = false
		corner.z_index = config.z_index + 1
		parent_control.add_child(corner)
		corners.append(corner)
	
	SlotCornerFactory.position_corners(corners, parent_control.size)

func show():
	"""Affiche avec animation fluide"""
	if is_visible: 
		return
	
	print("🎬 SlotVisualDisplay.show() - Animation vers %s%%" % (config.size_ratio * 100))
	
	is_visible = true
	
	# Rendre visible immédiatement
	for corner in corners:
		corner.visible = true
	
	if background:
		background.modulate.a = config.background_alpha
	
	# Animer les corners de leur taille actuelle vers la taille cible
	_animate_corners_to_size(config.size_ratio)

func hide():
	"""Cache avec animation fluide"""
	if not is_visible: 
		return
		
	print("🎬 SlotVisualDisplay.hide() - Animation vers 0%%")
	
	is_visible = false
	
	# Animer vers 0 avant de cacher
	_animate_corners_to_size(0.0, true)  # true = cacher à la fin

func _animate_corners_to_size(target_size: float, hide_at_end: bool = false):
	"""Anime les corners vers une nouvelle taille"""
	
	# Nettoyer le tween précédent
	if animation_tween and is_instance_valid(animation_tween):
		animation_tween.kill()
	
	# Créer un nouveau tween
	animation_tween = parent_control.create_tween()
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_QUART)
	
	# Animer la taille des corners
	animation_tween.tween_method(
		_update_corner_sizes, 
		current_corner_size, 
		target_size, 
		animation_duration
	)
	
	# Callback à la fin
	animation_tween.tween_callback(_on_animation_finished.bind(target_size, hide_at_end))

func _update_corner_sizes(size_ratio: float):
	"""Met à jour la taille des corners pendant l'animation"""
	current_corner_size = size_ratio
	
	if corners.is_empty():
		return
	
	var cell_size = 64  # Taille du slot
	var new_length = cell_size * size_ratio
	
	# Mettre à jour chaque corner
	for corner in corners:
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		if horizontal and vertical:
			# Redimensionner les barres
			horizontal.size.x = new_length
			vertical.size.y = new_length
			
			# Repositionner pour maintenir l'alignement selon le corner
			_reposition_corner_bars(corner, corners.find(corner), new_length)

func _reposition_corner_bars(corner: Control, corner_index: int, bar_length: float):
	"""Repositionne les barres d'un corner selon son index"""
	var horizontal = corner.get_child(0) as ColorRect
	var vertical = corner.get_child(1) as ColorRect
	var thickness = 2  # SlotCornerFactory.CORNER_THICKNESS
	
	match corner_index:
		0: # Top-left
			horizontal.position = Vector2.ZERO
			vertical.position = Vector2.ZERO
		1: # Top-right
			horizontal.position.x = -bar_length
			vertical.position.x = -thickness
		2: # Bottom-left
			horizontal.position.y = -thickness
			vertical.position.y = -bar_length
		3: # Bottom-right
			horizontal.position = Vector2(-bar_length, -thickness)
			vertical.position = Vector2(-thickness, -bar_length)

func _on_animation_finished(final_size: float, should_hide: bool):
	"""Callback à la fin de l'animation"""
	current_corner_size = final_size
	
	if should_hide:
		# Cacher complètement
		for corner in corners:
			corner.visible = false
		if background:
			background.modulate.a = 0.0

func cleanup():
	"""Nettoie les ressources"""
	if animation_tween and is_instance_valid(animation_tween):
		animation_tween.kill()
	animation_tween = null
	
	if background: 
		background.queue_free()
	for corner in corners:
		if corner: 
			corner.queue_free()
	corners.clear()
