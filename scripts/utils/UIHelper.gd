class_name UIHelper

static func find_node_safe(parent: Node, paths: Array) -> Node:
	"""Cherche un node avec plusieurs chemins possibles"""
	for path in paths:
		var node = parent.get_node_or_null(str(path))
		if node:
			return node
	return null

static func find_slots_grid(ui: Control) -> GridContainer:
	"""Trouve le GridContainer des slots avec tous les chemins possibles"""
	var paths = [
		"VBoxContainer/SlotsGrid",
		"HotbarGrid/GridContainer", 
		"SlotsGrid",
		"GridContainer"
	]
	return find_node_safe(ui, paths) as GridContainer

static func center_ui_horizontally(ui: Control, margin_from_top: float = 20.0):
	"""Centre une UI horizontalement avec marge depuis le haut"""
	await ui.get_tree().process_frame
	
	var viewport_size = ui.get_viewport().get_visible_rect().size
	var new_position = Vector2(
		(viewport_size.x - ui.size.x) / 2,
		margin_from_top
	)
	ui.position = new_position
