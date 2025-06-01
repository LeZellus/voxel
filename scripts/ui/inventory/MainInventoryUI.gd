# scripts/ui/inventory/MainInventoryUI.gd - VERSION RESPONSIVE
class_name MainInventoryUI
extends BaseInventoryUI

# === ANIMATION ===
var animation_tween: Tween
var original_position: Vector2

var FADE_DURATION: float = Constants.get_ui_fade_duration()
var SLIDE_DURATION: float = Constants.get_ui_slide_duration()
const SLIDE_EASE: Tween.EaseType = Tween.EASE_OUT
const SLIDE_TRANS: Tween.TransitionType = Tween.TRANS_BACK

# === RESPONSIVE ===
const MARGIN_BOTTOM: float = 4.0

# === SETUP ===

func _ready():
	super._ready()
	_setup_responsive_positioning()

func _setup_responsive_positioning():
	"""Configure le positionnement responsive"""
	await get_tree().process_frame
	
	# Se connecter au redimensionnement de la fenêtre
	get_viewport().size_changed.connect(_recalculate_position)
	
	# Position initiale
	_recalculate_position()
	
	# Commencer caché et en bas
	_set_to_hidden_state()

func _recalculate_position():
	"""Recalcule la position selon la taille actuelle du viewport"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Nouvelle position centrée horizontalement, en bas avec marge
	original_position = Vector2(
		(viewport_size.x - size.x) / 2,
		viewport_size.y - size.y - MARGIN_BOTTOM
	)
	
	# Si on est visible, mettre à jour immédiatement
	if visible and modulate.a > 0.5:
		position = original_position

func _set_to_hidden_state():
	"""Met l'UI dans son état caché initial"""
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(original_position.x, viewport_size.y)  # Hors écran en bas
	modulate.a = 0.0
	visible = false

# === AFFICHAGE AVEC ANIMATIONS ===

func show_ui():
	if animation_tween:
		animation_tween.kill()
	
	# Recalculer la position au cas où la fenêtre aurait changé
	_recalculate_position()
	
	visible = true
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de départ (hors écran)
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position = Vector2(original_position.x, viewport_size.y)
	position = start_position
	modulate.a = 0.0
	
	# Animations vers la position finale
	animation_tween.tween_property(self, "position", original_position, SLIDE_DURATION).set_ease(SLIDE_EASE).set_trans(SLIDE_TRANS)
	animation_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)

func hide_ui():
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de fin (hors écran)
	var viewport_size = get_viewport().get_visible_rect().size
	var end_position = Vector2(original_position.x, viewport_size.y)
	
	animation_tween.tween_property(self, "position", end_position, SLIDE_DURATION).set_ease(Tween.EASE_IN).set_trans(SLIDE_TRANS)
	animation_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	
	# Cacher complètement à la fin
	animation_tween.tween_callback(func(): visible = false).set_delay(SLIDE_DURATION)
