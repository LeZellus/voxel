# scripts/ui/inventory/MainInventoryUI.gd - SPÉCIALISÉE INVENTAIRE PRINCIPAL
class_name MainInventoryUI
extends BaseInventoryUI

# === ANIMATION ===
var animation_tween: Tween
var original_position: Vector2
var is_animating: bool = false

const SLIDE_DURATION: float = 0.8
const SLIDE_EASE: Tween.EaseType = Tween.EASE_OUT
const SLIDE_TRANS: Tween.TransitionType = Tween.TRANS_BACK
const FADE_DURATION: float = 0.5

# === SETUP ===

func _ready():
	super._ready()
	_setup_animations()

func _setup_animations():
	"""Positionne l'inventaire en bas de l'écran et le prépare pour l'animation."""
	# Attendre un frame pour s'assurer que la taille du contrôle est calculée
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	var ui_height = self.size.y # Récupère la hauteur réelle de votre nœud de contrôle UI
	var margin_bottom = 4 # Marge souhaitée depuis le bas de l'écran
	
	# Calcule la position finale de repos (original_position) pour qu'elle soit en bas
	# La position X reste la même, la position Y est calculée à partir du bas de l'écran	
	original_position = Vector2(position.x, viewport_size.y - ui_height - margin_bottom)	
	
	# Définit la position initiale (avant toute animation) pour qu'elle soit hors écran, en dessous du viewport
	position = Vector2(original_position.x, viewport_size.y) # Commence complètement hors écran en bas
	modulate.a = 0.0 # Commence invisible
	visible = false # Commence caché

# === AFFICHAGE AVEC ANIMATIONS ===

func show_ui():
	"""Affiche avec animation de slide"""
	if is_animating:
		return
	
	is_animating = true
	visible = true
	
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de départ
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position = Vector2(original_position.x, viewport_size.y)
	position = start_position
	modulate.a = 0.0
	
	# Animations
	animation_tween.tween_property(self, "position", original_position, SLIDE_DURATION).set_ease(SLIDE_EASE).set_trans(SLIDE_TRANS)
	animation_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	
	animation_tween.tween_callback(_on_show_animation_finished)

func hide_ui():
	"""Cache avec animation de slide"""
	if is_animating:
		return
	
	is_animating = true
	
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de fin
	var viewport_size = get_viewport().get_visible_rect().size
	var end_position = Vector2(original_position.x, viewport_size.y)
	
	animation_tween.tween_property(self, "position", end_position, SLIDE_DURATION).set_ease(Tween.EASE_IN).set_trans(SLIDE_TRANS)
	animation_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	
	animation_tween.tween_callback(_on_hide_animation_finished)

# === CALLBACKS ANIMATIONS ===

func _on_show_animation_finished():
	"""Callback fin d'animation d'ouverture"""
	is_animating = false

func _on_hide_animation_finished():
	"""Callback fin d'animation de fermeture"""
	visible = false
	is_animating = false
