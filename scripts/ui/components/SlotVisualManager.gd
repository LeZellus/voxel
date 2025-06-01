# scripts/ui/components/SlotVisualManager.gd
class_name SlotVisualManager
extends RefCounted

# === OVERLAYS ===
var hover_overlay: ColorRect
var selected_overlay: ColorRect
var parent_control: Control

# === ÉTATS ===
var is_hovered: bool = false
var is_selected: bool = false

func _init(parent: Control):
	parent_control = parent

func create_overlays():
	"""Crée et configure les overlays visuels"""
	await parent_control.get_tree().process_frame
	
	_create_hover_overlay()
	_create_selected_overlay()

func _create_hover_overlay():
	"""Crée l'overlay de survol"""
	hover_overlay = ColorRect.new()
	hover_overlay.name = "HoverOverlay"
	hover_overlay.color = Color(1, 1, 1, 0.15)
	hover_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_overlay.position = Vector2.ZERO
	hover_overlay.size = parent_control.size
	hover_overlay.visible = false
	hover_overlay.z_index = 50
	parent_control.add_child(hover_overlay)

func _create_selected_overlay():
	"""Crée l'overlay de sélection"""
	selected_overlay = ColorRect.new()
	selected_overlay.name = "SelectedOverlay"
	selected_overlay.color = Color(0.3, 0.7, 1.0, 0.4)
	selected_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_overlay.position = Vector2.ZERO
	selected_overlay.size = parent_control.size
	selected_overlay.visible = false
	selected_overlay.z_index = 51
	parent_control.add_child(selected_overlay)

# === API PUBLIQUE ===

func set_hover_state(hovered: bool):
	"""Active/désactive le survol"""
	if is_hovered == hovered:
		return
	is_hovered = hovered
	_update_visual_state()

func set_selected_state(selected: bool):
	"""Active/désactive la sélection"""
	if is_selected == selected:
		return
	is_selected = selected
	_update_visual_state()

func _update_visual_state():
	"""Met à jour l'affichage selon les états"""
	if not hover_overlay or not selected_overlay:
		return
	
	hover_overlay.visible = is_hovered and not is_selected
	selected_overlay.visible = is_selected

# === CUSTOMISATION ===

func set_hover_color(color: Color):
	"""Change la couleur du survol"""
	if hover_overlay:
		hover_overlay.color = color

func set_selected_color(color: Color):
	"""Change la couleur de sélection"""
	if selected_overlay:
		selected_overlay.color = color
