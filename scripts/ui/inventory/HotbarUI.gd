# scripts/ui/inventory/HotbarUI.gd - TOUJOURS CLIQUABLE
class_name HotbarUI
extends BaseInventoryUI

# === AFFICHAGE AVEC PRIORITÉ ===

func show_ui():
	"""Affiche la hotbar avec priorité d'affichage"""
	visible = true
	
func hide_ui():
	"""Cache la hotbar (normalement jamais appelé)"""
	visible = false

# === POSITIONNEMENT SÉCURISÉ ===

func _ready():
	super._ready()
	_setup_hotbar_position()

func _setup_hotbar_position():
	"""Positionne la hotbar en haut de l'écran"""
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	var new_position = Vector2(
		(viewport_size.x - size.x) / 2, 
		4
	)
	
	position = new_position
