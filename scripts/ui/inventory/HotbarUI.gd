# scripts/ui/inventory/HotbarUI.gd - TOUJOURS CLIQUABLE
class_name HotbarUI
extends BaseInventoryUI

# === CONFIGURATION HOTBAR ===

func get_grid_columns() -> int:
	return 9

func get_max_slots() -> int:
	return 9

func should_show_title() -> bool:
	return true

func get_slot_size() -> Vector2:
	return Vector2(64, 64)

# === AFFICHAGE AVEC PRIORITÉ ===

func show_ui():
	"""Affiche la hotbar avec priorité d'affichage"""
	visible = true
	modulate.a = 1.0
	
func hide_ui():
	"""Cache la hotbar (normalement jamais appelé)"""
	visible = false
	print("📦 Hotbar cachée")

# === POSITIONNEMENT SÉCURISÉ ===

func _ready():
	super._ready()
	_setup_hotbar_position()

func _setup_hotbar_position():
	"""Positionne la hotbar en haut de l'écran"""
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	var margin_top = 4
	var new_position = Vector2(
		(viewport_size.x - size.x) / 2, 
		margin_top
	)
	
	position = new_position
