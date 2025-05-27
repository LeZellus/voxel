# TooltipManager.gd - Gestionnaire global des tooltips
# À sauvegarder dans : res://scripts/managers/TooltipManager.gd
extends Node

signal tooltip_requested(item_data: Item, global_position: Vector2)
signal tooltip_hidden

var tooltip_scene: PackedScene
var current_tooltip: Control
var tooltip_parent: Control

func _ready():
	# Charge la scène de tooltip
	tooltip_scene = preload("res://scenes/ui/Tooltip.tscn")

func set_tooltip_parent(parent: Control):
	"""Définit le parent où afficher les tooltips (généralement l'UI principale)"""
	tooltip_parent = parent

func show_tooltip(item: Item, global_pos: Vector2):
	"""Affiche une tooltip pour un item à la position donnée"""
	if not item or not tooltip_parent:
		return
		
	hide_tooltip()
	
	current_tooltip = tooltip_scene.instantiate()
	tooltip_parent.add_child(current_tooltip)
	
	# Configure la tooltip
	if current_tooltip.has_method("setup_tooltip"):
		current_tooltip.setup_tooltip(item)
	
	# Attendre une frame pour que la taille soit calculée
	await get_tree().process_frame
	
	# Ajuste la position pour éviter les débordements
	var adjusted_pos = _adjust_position_for_screen(global_pos, current_tooltip.size)
	current_tooltip.global_position = adjusted_pos
	
	emit_signal("tooltip_requested", item, global_pos)

func _adjust_position_for_screen(pos: Vector2, tooltip_size: Vector2) -> Vector2:
	"""Ajuste la position pour garder la tooltip à l'écran"""
	if not tooltip_parent:
		return pos
		
	var screen_size = tooltip_parent.get_viewport().get_visible_rect().size
	var adjusted_pos = pos
	
	# Évite débordement à droite
	if pos.x + tooltip_size.x > screen_size.x:
		adjusted_pos.x = pos.x - tooltip_size.x - 10
	
	# Évite débordement en bas
	if pos.y + tooltip_size.y > screen_size.y:
		adjusted_pos.y = screen_size.y - tooltip_size.y - 10
	
	# Évite débordement en haut
	if adjusted_pos.y < 0:
		adjusted_pos.y = 10
		
	return adjusted_pos

func hide_tooltip():
	"""Cache la tooltip actuelle"""
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null
		emit_signal("tooltip_hidden")

func is_tooltip_visible() -> bool:
	"""Retourne true si une tooltip est actuellement affichée"""
	return current_tooltip != null
