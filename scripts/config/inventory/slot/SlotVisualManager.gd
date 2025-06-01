# scripts/ui/inventory/SlotVisualManager.gd - VERSION ROBUSTE
class_name SlotVisualManager
extends RefCounted

# === ÉTATS ===
enum VisualState { NONE, HOVER, SELECTED, ERROR }

# === COMPOSANTS ===
var parent_control: Control
var visual_layer: Control
var current_state: VisualState = VisualState.NONE
var pending_state: VisualState = VisualState.NONE

# === DONNÉES D'ÉTAT ===
var is_mouse_over: bool = false
var is_selected: bool = false
var error_timer: Timer

# === ANIMATIONS ===
var state_tween: Tween
var current_corners: Array[Control] = []
var current_background: ColorRect

func _init(parent: Control):
	parent_control = parent
	_setup_visual_layer()
	_setup_error_timer()

func _setup_visual_layer():
	"""Crée un layer dédié pour les visuels"""
	visual_layer = Control.new()
	visual_layer.name = "VisualOverlay"
	visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_layer.anchors_preset = Control.PRESET_FULL_RECT
	visual_layer.z_index = 100
	parent_control.add_child(visual_layer)

func _setup_error_timer():
	"""Crée le timer pour l'auto-masquage d'erreur"""
	error_timer = Timer.new()
	error_timer.wait_time = 1.0
	error_timer.one_shot = true
	error_timer.timeout.connect(_on_error_timeout)
	parent_control.add_child(error_timer)

# === API PUBLIQUE ===

func set_hover_state(hovered: bool):
	"""API pour gérer le survol"""
	is_mouse_over = hovered
	_update_visual_state()

func set_selected_state(selected: bool):
	"""API pour gérer la sélection"""
	is_selected = selected
	_update_visual_state()

func show_error_feedback():
	"""API pour afficher une erreur"""
	_change_to_state(VisualState.ERROR)
	error_timer.start()

# === LOGIQUE D'ÉTAT ===

func _update_visual_state():
	"""Détermine l'état visuel selon les conditions"""
	var target_state: VisualState
	
	# Priorité : sélection > survol > rien
	if is_selected:
		target_state = VisualState.SELECTED
	elif is_mouse_over:
		target_state = VisualState.HOVER
	else:
		target_state = VisualState.NONE
	
	# Ne pas écraser l'erreur sauf si explicitement demandé
	if current_state == VisualState.ERROR and error_timer.time_left > 0:
		pending_state = target_state  # Sauvegarder pour après l'erreur
		return
	
	_change_to_state(target_state)

func _change_to_state(new_state: VisualState):
	"""Change immédiatement vers un nouvel état"""
	if current_state == new_state:
		return
	
	print("🎨 Slot[%d]: %s -> %s" % [
		parent_control.get_index() if parent_control else -1,
		VisualState.keys()[current_state], 
		VisualState.keys()[new_state]
	])
	
	# Nettoyer l'état précédent
	_cleanup_current_visuals()
	
	# Appliquer le nouvel état
	current_state = new_state
	_apply_visual_state(new_state)

func _on_error_timeout():
	"""Callback de fin d'erreur"""
	print("⏰ Fin timer erreur - retour à l'état pending")
	
	# Revenir à l'état qui était en attente
	var target_state = pending_state if pending_state != VisualState.ERROR else VisualState.NONE
	pending_state = VisualState.NONE
	
	# Si on a encore les conditions pour un état, l'appliquer
	if target_state == VisualState.NONE:
		_update_visual_state()
	else:
		_change_to_state(target_state)

# === RENDU VISUEL ===

func _apply_visual_state(state: VisualState):
	"""Applique le rendu pour un état donné"""
	match state:
		VisualState.NONE:
			# Rien à afficher
			pass
		VisualState.HOVER:
			_create_visual_overlay(SlotVisualConfig.HOVER)
		VisualState.SELECTED:
			_create_visual_overlay(SlotVisualConfig.SELECTED)
		VisualState.ERROR:
			_create_error_overlay()

func _create_visual_overlay(config: Dictionary):
	"""Crée un overlay standard avec animation"""
	# Background
	current_background = ColorRect.new()
	current_background.color = config.background_color
	current_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_background.anchors_preset = Control.PRESET_FULL_RECT
	current_background.modulate.a = 0.0
	visual_layer.add_child(current_background)
	
	# Corners
	_create_animated_corners(config)
	
	# Animation d'entrée
	_animate_in(config)

func _create_animated_corners(config: Dictionary):
	"""Crée les corners animés"""
	current_corners.clear()
	var size = parent_control.size
	
	for i in range(4):
		var corner = _create_corner(config.corner_color)
		visual_layer.add_child(corner)
		current_corners.append(corner)
	
	_position_corners(size)

func _create_corner(color: Color) -> Control:
	"""Crée un corner individuel"""
	var container = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Barre horizontale
	var h_bar = ColorRect.new()
	h_bar.color = color
	h_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_bar.size = Vector2(0, 2)  # Commence à 0
	container.add_child(h_bar)
	
	# Barre verticale
	var v_bar = ColorRect.new()
	v_bar.color = color
	v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_bar.size = Vector2(2, 0)  # Commence à 0
	container.add_child(v_bar)
	
	return container

func _position_corners(size: Vector2):
	"""Positionne les corners aux angles"""
	if current_corners.size() != 4:
		return
	
	var positions = [
		Vector2.ZERO,           # Top-left
		Vector2(size.x, 0),     # Top-right
		Vector2(0, size.y),     # Bottom-left
		Vector2(size.x, size.y) # Bottom-right
	]
	
	for i in range(4):
		current_corners[i].position = positions[i]

func _animate_in(config: Dictionary):
	"""Animation d'apparition"""
	_cleanup_tween()
	
	state_tween = visual_layer.create_tween()
	state_tween.set_parallel(true)
	
	# Fade du background
	if current_background:
		state_tween.tween_property(current_background, "modulate:a", config.background_alpha, 0.15)
	
	# Croissance des corners
	var target_length = parent_control.size.x * config.size_ratio
	state_tween.tween_method(_update_corner_sizes, 0.0, target_length, 0.2).set_ease(Tween.EASE_OUT)

func _create_error_overlay():
	"""Crée l'overlay d'erreur avec shake"""
	_create_visual_overlay(SlotVisualConfig.ERROR)
	
	# Ajouter l'effet de shake après la création
	_add_shake_effect()

func _add_shake_effect():
	"""Ajoute l'effet de shake à l'overlay existant"""
	if not state_tween:
		return
	
	# Shake de l'ensemble du layer visuel
	state_tween.tween_method(_shake_visuals, 0.0, 1.0, 0.4).set_ease(Tween.EASE_OUT)

func _shake_visuals(progress: float):
	"""Applique le shake sur tous les visuels"""
	if not visual_layer:
		return
	
	var intensity = 3.0 * (1.0 - progress)
	var offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)
	
	# Shake de tout le layer
	visual_layer.position = offset

func _update_corner_sizes(length: float):
	"""Met à jour la taille des corners pendant l'animation"""
	for i in range(current_corners.size()):
		var corner = current_corners[i]
		if not corner or corner.get_child_count() < 2:
			continue
		
		var h_bar = corner.get_child(0) as ColorRect
		var v_bar = corner.get_child(1) as ColorRect
		
		# Redimensionner
		h_bar.size.x = length
		v_bar.size.y = length
		
		# Repositionner selon l'angle
		match i:
			1: # Top-right
				h_bar.position.x = -length
				v_bar.position.x = -2
			2: # Bottom-left
				h_bar.position.y = -2
				v_bar.position.y = -length
			3: # Bottom-right
				h_bar.position = Vector2(-length, -2)
				v_bar.position = Vector2(-2, -length)

# === NETTOYAGE ===

func _cleanup_current_visuals():
	"""Nettoie tous les visuels actuels"""
	_cleanup_tween()
	
	# Remettre le layer à zéro
	if visual_layer:
		visual_layer.position = Vector2.ZERO
		for child in visual_layer.get_children():
			child.queue_free()
	
	current_corners.clear()
	current_background = null

func _cleanup_tween():
	"""Nettoie le tween actuel"""
	if state_tween and is_instance_valid(state_tween):
		state_tween.kill()
	state_tween = null

func cleanup():
	"""Nettoyage complet"""
	_cleanup_current_visuals()
	
	if error_timer:
		error_timer.queue_free()
	
	if visual_layer:
		visual_layer.queue_free()

# === DEBUG ===

func debug_state():
	"""Debug de l'état actuel"""
	print("🔍 SlotVisualManager Debug:")
	print("   - État: %s" % VisualState.keys()[current_state])
	print("   - Pending: %s" % VisualState.keys()[pending_state])
	print("   - Mouse over: %s" % is_mouse_over)
	print("   - Selected: %s" % is_selected)
	print("   - Error timer: %s" % error_timer.time_left)
