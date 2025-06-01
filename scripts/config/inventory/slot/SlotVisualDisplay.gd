class_name SlotVisualDisplay
extends RefCounted

var parent_control: Control
var config: Dictionary
var corners: Array[Control] = []
var background: ColorRect
var animation_tween: Tween
var is_visible: bool = false
var is_mouse_over: bool = false

func _init(parent: Control, display_config: Dictionary):
	parent_control = parent
	config = display_config
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
		var corner = SlotCornerFactory.create_corner(config.corner_color, config.size_ratio)
		corner.visible = false
		corner.z_index = config.z_index + 1
		parent_control.add_child(corner)
		corners.append(corner)
	
	SlotCornerFactory.position_corners(corners, parent_control.size)

func show():
	if is_visible: return
	is_visible = true
	
	for corner in corners:
		corner.visible = true
	if background:
		background.modulate.a = config.background_alpha

func hide():
	if not is_visible: return
	is_visible = false
	
	for corner in corners:
		corner.visible = false
	if background:
		background.modulate.a = 0.0

func cleanup():
	if background: background.queue_free()
	for corner in corners:
		if corner: corner.queue_free()
	corners.clear()
