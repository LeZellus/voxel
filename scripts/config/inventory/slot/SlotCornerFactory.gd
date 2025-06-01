class_name SlotCornerFactory
extends RefCounted

const CORNER_THICKNESS = 2

static func create_corner(color: Color, size_ratio: float) -> Control:
	var container = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var cell_size = 64  # Taille fixe temporaire
	var bar_length = cell_size * size_ratio
	
	var horizontal = ColorRect.new()
	horizontal.color = color
	horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal.size = Vector2(bar_length, CORNER_THICKNESS)
	container.add_child(horizontal)
	
	var vertical = ColorRect.new()
	vertical.color = color
	vertical.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vertical.size = Vector2(CORNER_THICKNESS, bar_length)
	container.add_child(vertical)
	
	return container

static func position_corners(corners: Array[Control], size: Vector2):
	if corners.size() != 4: return
	
	corners[0].position = Vector2.ZERO
	corners[1].position = Vector2(size.x, 0)
	corners[2].position = Vector2(0, size.y)
	corners[3].position = Vector2(size.x, size.y)
	
	for i in range(4):
		_orient_corner(corners[i], i)

static func _orient_corner(corner: Control, index: int):
	var horizontal = corner.get_child(0) as ColorRect
	var vertical = corner.get_child(1) as ColorRect
	var length = horizontal.size.x
	
	match index:
		1: # Top-right
			horizontal.position.x = -length
			vertical.position.x = -CORNER_THICKNESS
		2: # Bottom-left
			horizontal.position.y = -CORNER_THICKNESS
			vertical.position.y = -length
		3: # Bottom-right
			horizontal.position = Vector2(-length, -CORNER_THICKNESS)
			vertical.position = Vector2(-CORNER_THICKNESS, -length)
