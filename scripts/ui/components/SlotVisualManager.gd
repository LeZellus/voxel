# scripts/ui/components/SlotVisualManager.gd - AVEC ÉTAT REFUSÉ
class_name SlotVisualManager
extends RefCounted

# === OVERLAYS ===
var hover_corners: Array[Control] = []
var selected_corners: Array[Control] = []
var error_corners: Array[Control] = []  # NOUVEAU: coins d'erreur
var selected_background: ColorRect
var error_background: ColorRect  # NOUVEAU: fond d'erreur
var parent_control: Control

# === ÉTATS ===
var is_hovered: bool = false
var is_selected: bool = false
var is_error: bool = false  # NOUVEAU: état d'erreur

# === CONFIGURATION ===
const CORNER_THICKNESS = 2
const HOVER_SIZE_RATIO = 0.25
const SELECTED_SIZE_RATIO = 0.5
const ERROR_SIZE_RATIO = 0.4  # NOUVEAU: taille pour l'erreur

# === COULEURS ===
const HOVER_COLOR = Color("#c7cfcc")
const SELECTED_COLOR = Color("#577277")
const SELECTED_BACKGROUND_COLOR = Color("#151d28")
const ERROR_COLOR = Color("#e74c3c")  # NOUVEAU: rouge pour erreur
const ERROR_BACKGROUND_COLOR = Color("#2c1810")  # NOUVEAU: fond rouge sombre

# === ANIMATION ===
const ANIMATION_DURATION = 0.3
const ERROR_ANIMATION_DURATION = 0.15  # NOUVEAU: animation plus rapide pour erreur
const ERROR_AUTO_HIDE_DELAY = 0.8  # NOUVEAU: cache automatiquement après 0.8s
const BACKGROUND_FADE_DURATION = 0.1
const ANIMATION_EASE = Tween.EASE_OUT
const ANIMATION_TRANS = Tween.TRANS_BACK
var animation_tween: Tween
var error_hide_timer: Timer  # NOUVEAU: timer pour cacher automatiquement

func _init(parent: Control):
	parent_control = parent

func create_overlays():
	"""Crée et configure les overlays visuels"""
	await parent_control.get_tree().process_frame
	
	_create_selected_background()
	_create_error_background()  # NOUVEAU
	_create_hover_corners()
	_create_selected_corners()
	_create_error_corners()  # NOUVEAU
	_create_error_timer()  # NOUVEAU

func _create_selected_background():
	"""Crée le fond de sélection"""
	selected_background = ColorRect.new()
	selected_background.name = "SelectedBackground"
	selected_background.color = SELECTED_BACKGROUND_COLOR
	selected_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_background.position = Vector2.ZERO
	selected_background.size = parent_control.size
	selected_background.modulate.a = 0.0
	selected_background.visible = true
	selected_background.z_index = 45
	parent_control.add_child(selected_background)

func _create_error_background():
	"""NOUVEAU: Crée le fond d'erreur"""
	error_background = ColorRect.new()
	error_background.name = "ErrorBackground"
	error_background.color = ERROR_BACKGROUND_COLOR
	error_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_background.position = Vector2.ZERO
	error_background.size = parent_control.size
	error_background.modulate.a = 0.0
	error_background.visible = true
	error_background.z_index = 46  # Au-dessus du fond de sélection
	parent_control.add_child(error_background)

func _create_hover_corners():
	"""Crée les coins de survol"""
	hover_corners.clear()
	
	for i in range(4):
		var corner = _create_corner_shape(HOVER_COLOR, HOVER_SIZE_RATIO)
		corner.name = "HoverCorner" + str(i)
		corner.visible = false
		corner.z_index = 50
		parent_control.add_child(corner)
		hover_corners.append(corner)
	
	_position_corners(hover_corners)

func _create_selected_corners():
	"""Crée les coins de sélection"""
	selected_corners.clear()
	
	for i in range(4):
		var corner = _create_corner_shape(SELECTED_COLOR, HOVER_SIZE_RATIO)
		corner.name = "SelectedCorner" + str(i)
		corner.visible = false
		corner.z_index = 51
		parent_control.add_child(corner)
		selected_corners.append(corner)
	
	_position_corners(selected_corners)

func _create_error_corners():
	"""NOUVEAU: Crée les coins d'erreur"""
	error_corners.clear()
	
	for i in range(4):
		var corner = _create_corner_shape(ERROR_COLOR, HOVER_SIZE_RATIO)
		corner.name = "ErrorCorner" + str(i)
		corner.visible = false
		corner.z_index = 52  # Au-dessus de tout
		parent_control.add_child(corner)
		error_corners.append(corner)
	
	_position_corners(error_corners)

func _create_error_timer():
	"""NOUVEAU: Crée le timer pour cacher automatiquement l'erreur"""
	error_hide_timer = Timer.new()
	error_hide_timer.name = "ErrorHideTimer"
	error_hide_timer.wait_time = ERROR_AUTO_HIDE_DELAY
	error_hide_timer.one_shot = true
	error_hide_timer.timeout.connect(_auto_hide_error)
	parent_control.add_child(error_hide_timer)

func _create_corner_shape(color: Color, size_ratio: float) -> Control:
	"""Crée un coin en forme de L"""
	var container = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var cell_size = parent_control.size.x
	var bar_length = cell_size * size_ratio
	
	# Barre horizontale du L
	var horizontal = ColorRect.new()
	horizontal.color = color
	horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal.size = Vector2(bar_length, CORNER_THICKNESS)
	container.add_child(horizontal)
	
	# Barre verticale du L
	var vertical = ColorRect.new()
	vertical.color = color
	vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical.size = Vector2(CORNER_THICKNESS, bar_length)
	container.add_child(vertical)
	
	return container

func _position_corners(corners: Array[Control]):
	"""Positionne les coins aux 4 angles"""
	if corners.size() != 4:
		return
	
	var size = parent_control.size
	
	# Coin haut-gauche
	corners[0].position = Vector2.ZERO
	_orient_corner(corners[0], "top_left")
	
	# Coin haut-droit
	corners[1].position = Vector2(size.x, 0)
	_orient_corner(corners[1], "top_right")
	
	# Coin bas-gauche
	corners[2].position = Vector2(0, size.y)
	_orient_corner(corners[2], "bottom_left")
	
	# Coin bas-droit
	corners[3].position = Vector2(size.x, size.y)
	_orient_corner(corners[3], "bottom_right")

func _orient_corner(corner: Control, orientation: String):
	"""Oriente les barres du L selon la position"""
	var horizontal = corner.get_child(0) as ColorRect
	var vertical = corner.get_child(1) as ColorRect
	var bar_length = horizontal.size.x
	
	match orientation:
		"top_left":
			horizontal.position = Vector2.ZERO
			vertical.position = Vector2.ZERO
		"top_right":
			horizontal.position = Vector2(-bar_length, 0)
			vertical.position = Vector2(-CORNER_THICKNESS, 0)
		"bottom_left":
			horizontal.position = Vector2(0, -CORNER_THICKNESS)
			vertical.position = Vector2(0, -bar_length)
		"bottom_right":
			horizontal.position = Vector2(-bar_length, -CORNER_THICKNESS)
			vertical.position = Vector2(-CORNER_THICKNESS, -bar_length)

# === API PUBLIQUE ===

func set_hover_state(hovered: bool):
	"""Active/désactive le survol"""
	if is_hovered == hovered:
		return
	is_hovered = hovered
	_update_visual_state()

func set_selected_state(selected: bool):
	"""Active/désactive la sélection avec animation"""
	if is_selected == selected:
		return
	is_selected = selected
	
	if selected:
		_animate_to_selected()
	else:
		_animate_to_hover()
	
	_update_visual_state()

func show_error_feedback():
	"""NOUVEAU: Affiche le feedback d'erreur (action refusée)"""
	# Arrêter toute animation en cours
	if animation_tween:
		animation_tween.kill()
	
	# Désactiver les autres états visuels temporairement
	_hide_all_states()
	
	is_error = true
	
	# Animer l'apparition de l'erreur
	_animate_error_show()
	
	# Programmer la disparition automatique
	error_hide_timer.start()

func _hide_all_states():
	"""Cache tous les états visuels"""
	for corner in hover_corners:
		if corner and is_instance_valid(corner):
			corner.visible = false
	
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = false
	
	if selected_background:
		selected_background.modulate.a = 0.0

func _animate_error_show():
	"""NOUVEAU: Anime l'apparition de l'erreur"""
	animation_tween = parent_control.create_tween()
	animation_tween.set_parallel(true)
	
	animation_tween.tween_method(_shake_effect, 0.0, 1.0, ERROR_ANIMATION_DURATION * 2).set_ease(Tween.EASE_OUT)
	
	# Rendre visibles les coins d'erreur
	for corner in error_corners:
		if corner and is_instance_valid(corner):
			corner.visible = true
	
	var cell_size = parent_control.size.x
	var target_length = cell_size * ERROR_SIZE_RATIO
	
	# Fade du fond d'erreur
	animation_tween.tween_property(error_background, "modulate:a", 0.6, ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	
	# Animer les coins vers la taille d'erreur
	for i in range(error_corners.size()):
		var corner = error_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		# Animer la taille avec un bounce
		animation_tween.tween_property(horizontal, "size", Vector2(target_length, CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, target_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		# Ajuster les positions
		match i:
			0: # Top-left
				pass
			1: # Top-right
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, 0), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			2: # Bottom-left
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				animation_tween.tween_property(vertical, "position", Vector2(0, -target_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			3: # Bottom-right
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, -CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				animation_tween.tween_property(vertical, "position", Vector2(-CORNER_THICKNESS, -target_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _auto_hide_error():
	"""NOUVEAU: Cache automatiquement l'erreur après le délai"""
	_animate_error_hide()

func _animate_error_hide():
	"""NOUVEAU: Anime la disparition de l'erreur"""
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = parent_control.create_tween()
	animation_tween.set_parallel(true)
	
	# Fade out du fond
	animation_tween.tween_property(error_background, "modulate:a", 0.0, ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
	
	var cell_size = parent_control.size.x
	var original_length = cell_size * HOVER_SIZE_RATIO
	
	# Réduire les coins vers la taille originale
	for i in range(error_corners.size()):
		var corner = error_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		animation_tween.tween_property(horizontal, "size", Vector2(original_length, CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, original_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
		
		# Retour aux positions originales
		match i:
			0: # Top-left
				pass
			1: # Top-right
				animation_tween.tween_property(horizontal, "position", Vector2(-original_length, 0), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
			2: # Bottom-left
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
				animation_tween.tween_property(vertical, "position", Vector2(0, -original_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
			3: # Bottom-right
				animation_tween.tween_property(horizontal, "position", Vector2(-original_length, -CORNER_THICKNESS), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
				animation_tween.tween_property(vertical, "position", Vector2(-CORNER_THICKNESS, -original_length), ERROR_ANIMATION_DURATION).set_ease(Tween.EASE_IN)
	
	# Cacher complètement à la fin et restaurer l'état normal
	animation_tween.tween_callback(_finish_error_hide).set_delay(ERROR_ANIMATION_DURATION)

func _finish_error_hide():
	"""NOUVEAU: Termine la disparition de l'erreur et restaure l'état normal"""
	is_error = false
	
	# Cacher tous les coins d'erreur
	for corner in error_corners:
		if corner and is_instance_valid(corner):
			corner.visible = false
	
	# Restaurer l'état visuel normal
	_update_visual_state()

func _update_visual_state():
	"""Met à jour l'affichage selon les états (modifié pour inclure l'erreur)"""
	# Si en état d'erreur, ne pas toucher aux autres visuels
	if is_error:
		return
	
	# Afficher les coins de survol seulement si survolé et pas sélectionné
	for corner in hover_corners:
		if corner and is_instance_valid(corner):
			corner.visible = is_hovered and not is_selected
	
	# Afficher les coins de sélection si sélectionné
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = is_selected

# === ANIMATIONS EXISTANTES (inchangées) ===

func _animate_to_selected():
	"""Anime l'expansion vers la taille sélectionnée"""
	if animation_tween:
		animation_tween.kill()
	
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = true
	
	animation_tween = parent_control.create_tween()
	animation_tween.set_parallel(true)
	
	var cell_size = parent_control.size.x
	var current_length = cell_size * HOVER_SIZE_RATIO
	var target_length = cell_size * SELECTED_SIZE_RATIO
	
	animation_tween.tween_property(selected_background, "modulate:a", 1.0, BACKGROUND_FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		animation_tween.tween_property(horizontal, "size", Vector2(target_length, CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		
		match i:
			0: pass
			1: animation_tween.tween_property(horizontal, "position", Vector2(-target_length, 0), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			2: 
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(0, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			3: 
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(-CORNER_THICKNESS, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)

func _animate_to_hover():
	"""Anime la réduction vers la taille de survol"""
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = parent_control.create_tween()
	animation_tween.set_parallel(true)
	
	var cell_size = parent_control.size.x
	var target_length = cell_size * HOVER_SIZE_RATIO
	
	animation_tween.tween_property(selected_background, "modulate:a", 0.0, BACKGROUND_FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		animation_tween.tween_property(horizontal, "size", Vector2(target_length, CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		
		match i:
			0: pass
			1: animation_tween.tween_property(horizontal, "position", Vector2(-target_length, 0), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			2: 
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(0, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			3: 
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(-CORNER_THICKNESS, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
	
	animation_tween.tween_callback(_hide_selected_corners).set_delay(ANIMATION_DURATION)

func _hide_selected_corners():
	"""Cache les coins sélectionnés"""
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = false

# === UTILITAIRES ===

func cleanup():
	"""Nettoie les ressources"""
	if animation_tween:
		animation_tween.kill()
	
	if error_hide_timer and is_instance_valid(error_hide_timer):
		error_hide_timer.queue_free()
	
	if selected_background and is_instance_valid(selected_background):
		selected_background.queue_free()
	
	if error_background and is_instance_valid(error_background):
		error_background.queue_free()
	
	for corner in hover_corners + selected_corners + error_corners:
		if corner and is_instance_valid(corner):
			corner.queue_free()
	
	hover_corners.clear()
	selected_corners.clear()
	error_corners.clear()
	
	
func _shake_effect(progress: float):
	"""Effet de tremblement pendant l'erreur"""
	if not parent_control or not is_error:
		return
	
	var shake_intensity = 3.0 * (1.0 - progress)  # Diminue avec le temps
	var offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	
	# Sauvegarder les positions originales et appliquer le tremblement
	for i in range(error_corners.size()):
		var corner = error_corners[i]
		if corner and is_instance_valid(corner):
			var original_pos = _get_original_corner_position(i)
			corner.position = original_pos + offset
	
	if error_background:
		error_background.position = Vector2.ZERO + offset

func _get_original_corner_position(corner_index: int) -> Vector2:
	"""Retourne la position originale d'un coin selon son index"""
	var size = parent_control.size
	match corner_index:
		0: return Vector2.ZERO  # Top-left
		1: return Vector2(size.x, 0)  # Top-right
		2: return Vector2(0, size.y)  # Bottom-left
		3: return Vector2(size.x, size.y)  # Bottom-right
		_: return Vector2.ZERO
