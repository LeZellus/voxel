# scripts/ui/inventory/HotbarUI.gd
class_name HotbarUI
extends BaseInventoryUI

# === CONFIGURATION HOTBAR ===

func get_grid_columns() -> int:
	return 9  # Hotbar horizontale

func get_max_slots() -> int:
	return 9  # Hotbar fixe à 9 slots

func should_show_title() -> bool:
	return true  # Pas de titre pour la hotbar

func get_slot_size() -> Vector2:
	return Vector2(64, 64)

# === AFFICHAGE SIMPLE ===

func show_ui():
	"""Affiche la hotbar (toujours visible)"""
	visible = true
	modulate.a = 1.0
	print("📦 Hotbar affichée")

func hide_ui():
	"""Cache la hotbar"""
	visible = false
	print("📦 Hotbar cachée")

# === POSITIONNEMENT ===

func _ready():
	super._ready()
	_setup_hotbar_position()

func _setup_hotbar_position():
	"""Positionne la hotbar en bas de l'écran"""
	# Attendre que la scène soit prête
	await get_tree().process_frame
	
	# Centrer horizontalement, placer en bas
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position centrée en bas avec marge
	var margin_top = 4
	var new_position = Vector2(
		(viewport_size.x - size.x) / 2, margin_top
	)
	
	position = new_position
	print("📍 Hotbar positionnée: %s" % new_position)
