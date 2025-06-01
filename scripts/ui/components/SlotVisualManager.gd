# scripts/ui/components/SlotVisualManager.gd
class_name SlotVisualManager
extends RefCounted

# === OVERLAYS ===
var hover_corners: Array[Control] = []
var selected_corners: Array[Control] = []
var selected_background: ColorRect
var parent_control: Control

# === ÉTATS ===
var is_hovered: bool = false
var is_selected: bool = false

# === CONFIGURATION ===
const CORNER_THICKNESS = 2
const HOVER_SIZE_RATIO = 0.25  # 1/3 de la cellule
const SELECTED_SIZE_RATIO = 0.5  # 50% de la cellule
const HOVER_COLOR = Color("#c7cfcc")
const SELECTED_COLOR = Color("#577277")
const SELECTED_BACKGROUND_COLOR = Color("#151d28")

# === ANIMATION ===
const ANIMATION_DURATION = 0.3
const BACKGROUND_FADE_DURATION = 0.1  # Fade rapide pour le fond
const ANIMATION_EASE = Tween.EASE_OUT
const ANIMATION_TRANS = Tween.TRANS_BACK
var animation_tween: Tween

func _init(parent: Control):
	parent_control = parent

func create_overlays():
	"""Crée et configure les overlays visuels"""
	await parent_control.get_tree().process_frame
	
	_create_selected_background()
	_create_hover_corners()
	_create_selected_corners()

func _create_selected_background():
	"""Crée le fond de sélection"""
	selected_background = ColorRect.new()
	selected_background.name = "SelectedBackground"
	selected_background.color = SELECTED_BACKGROUND_COLOR
	selected_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_background.position = Vector2.ZERO
	selected_background.size = parent_control.size
	selected_background.modulate.a = 0.0  # Commence invisible
	selected_background.visible = true  # Mais visible pour permettre le fade
	selected_background.z_index = 45  # Derrière les coins
	parent_control.add_child(selected_background)

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
		var corner = _create_corner_shape(SELECTED_COLOR, HOVER_SIZE_RATIO)  # Commencent petits
		corner.name = "SelectedCorner" + str(i)
		corner.visible = false
		corner.z_index = 51
		parent_control.add_child(corner)
		selected_corners.append(corner)
	
	_position_corners(selected_corners)

func _create_corner_shape(color: Color, size_ratio: float) -> Control:
	"""Crée un coin en forme de L"""
	var container = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var cell_size = parent_control.size.x  # Assume une cellule carrée
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
	var bar_length = horizontal.size.x  # Longueur actuelle
	
	match orientation:
		"top_left":
			# L normal
			horizontal.position = Vector2.ZERO
			vertical.position = Vector2.ZERO
		
		"top_right":
			# L retourné horizontalement
			horizontal.position = Vector2(-bar_length, 0)
			vertical.position = Vector2(-CORNER_THICKNESS, 0)
		
		"bottom_left":
			# L retourné verticalement
			horizontal.position = Vector2(0, -CORNER_THICKNESS)
			vertical.position = Vector2(0, -bar_length)
		
		"bottom_right":
			# L retourné dans les deux sens
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

func _update_visual_state():
	"""Met à jour l'affichage selon les états"""
	# Afficher les coins de survol seulement si survolé et pas sélectionné
	for corner in hover_corners:
		if corner and is_instance_valid(corner):
			corner.visible = is_hovered and not is_selected
	
	# Afficher les coins de sélection si sélectionné
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = is_selected

# === ANIMATIONS ===

func _animate_to_selected():
	"""Anime l'expansion vers la taille sélectionnée"""
	if animation_tween:
		animation_tween.kill()
	
	# Rendre visibles immédiatement
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = true
	
	animation_tween = parent_control.create_tween()
	animation_tween.set_parallel(true)
	
	var cell_size = parent_control.size.x
	var current_length = cell_size * HOVER_SIZE_RATIO
	var target_length = cell_size * SELECTED_SIZE_RATIO
	var growth = target_length - current_length
	
	# Fade rapide du fond en parallèle dès le début
	animation_tween.tween_property(selected_background, "modulate:a", 1.0, BACKGROUND_FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		# Animer la taille
		animation_tween.tween_property(horizontal, "size", Vector2(target_length, CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		
		# Ajuster les positions pour grandir vers l'intérieur
		match i:
			0: # Top-left - grandit vers la droite et le bas (OK)
				pass
			
			1: # Top-right - grandit vers la gauche et le bas
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, 0), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			
			2: # Bottom-left - grandit vers la droite et le haut
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(0, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			
			3: # Bottom-right - grandit vers la gauche et le haut
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
	
	# Fade rapide du fond pour le cacher dès le début
	animation_tween.tween_property(selected_background, "modulate:a", 0.0, BACKGROUND_FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	for i in range(selected_corners.size()):
		var corner = selected_corners[i]
		if not corner or not is_instance_valid(corner):
			continue
		
		var horizontal = corner.get_child(0) as ColorRect
		var vertical = corner.get_child(1) as ColorRect
		
		# Animer la taille
		animation_tween.tween_property(horizontal, "size", Vector2(target_length, CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		animation_tween.tween_property(vertical, "size", Vector2(CORNER_THICKNESS, target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
		
		# Retour aux positions originales
		match i:
			0: # Top-left
				pass
			
			1: # Top-right
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, 0), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			
			2: # Bottom-left
				animation_tween.tween_property(horizontal, "position", Vector2(0, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(0, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
			
			3: # Bottom-right
				animation_tween.tween_property(horizontal, "position", Vector2(-target_length, -CORNER_THICKNESS), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
				animation_tween.tween_property(vertical, "position", Vector2(-CORNER_THICKNESS, -target_length), ANIMATION_DURATION).set_ease(ANIMATION_EASE).set_trans(ANIMATION_TRANS)
	
	# Cacher les coins à la fin
	animation_tween.tween_callback(_hide_selected_corners).set_delay(ANIMATION_DURATION)

func _hide_selected_corners():
	"""Cache les coins sélectionnés"""
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.visible = false

# === CUSTOMISATION ===

func set_hover_color(color: Color):
	"""Change la couleur du survol"""
	for corner in hover_corners:
		if corner and is_instance_valid(corner):
			_update_corner_color(corner, color)

func set_selected_color(color: Color):
	"""Change la couleur de sélection"""
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			_update_corner_color(corner, color)

func _update_corner_color(corner: Control, color: Color):
	"""Met à jour la couleur d'un coin"""
	for child in corner.get_children():
		if child is ColorRect:
			child.color = color

# === UTILITAIRES ===

func cleanup():
	"""Nettoie les ressources"""
	if animation_tween:
		animation_tween.kill()
	
	if selected_background and is_instance_valid(selected_background):
		selected_background.queue_free()
	
	for corner in hover_corners:
		if corner and is_instance_valid(corner):
			corner.queue_free()
	
	for corner in selected_corners:
		if corner and is_instance_valid(corner):
			corner.queue_free()
	
	hover_corners.clear()
	selected_corners.clear()
