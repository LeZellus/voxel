# scripts/ui/inventory/MainInventoryUI.gd - SPÉCIALISÉE INVENTAIRE PRINCIPAL
class_name MainInventoryUI
extends BaseInventoryUI

# === ANIMATION ===
var animation_tween: Tween
var original_position: Vector2
var is_animating: bool = false

const SLIDE_DURATION: float = 0.4
const SLIDE_EASE: Tween.EaseType = Tween.EASE_OUT
const SLIDE_TRANS: Tween.TransitionType = Tween.TRANS_BACK
const FADE_DURATION: float = 0.3

# === CONFIGURATION INVENTAIRE PRINCIPAL ===

func get_grid_columns() -> int:
	return 9

func get_max_slots() -> int:
	return inventory.size if inventory else 45

func should_show_title() -> bool:
	return true

# === SETUP ===

func _ready():
	super._ready()
	_setup_animations()

func _setup_animations():
	"""Configure les propriétés d'animation"""
	original_position = position
	
	# Position de départ (hors écran vers le bas)
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position = Vector2(original_position.x, viewport_size.y)
	
	# Démarrer invisible et en bas
	position = start_position
	modulate.a = 0.0
	visible = false

# === AFFICHAGE AVEC ANIMATIONS ===

func show_ui():
	"""Affiche avec animation de slide"""
	if is_animating:
		return
	
	print("🎬 Animation d'ouverture inventaire")
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
	
	_animate_slots_cascade_in()
	animation_tween.tween_callback(_on_show_animation_finished)

func hide_ui():
	"""Cache avec animation de slide"""
	if is_animating:
		return
	
	print("🎬 Animation fermeture inventaire")
	is_animating = true
	
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de fin
	var viewport_size = get_viewport().get_visible_rect().size
	var end_position = Vector2(original_position.x, viewport_size.y)
	
	animation_tween.tween_property(self, "position", end_position, SLIDE_DURATION).set_ease(Tween.EASE_IN).set_trans(SLIDE_TRANS)
	animation_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	
	_animate_slots_cascade_out()
	animation_tween.tween_callback(_on_hide_animation_finished)

# === ANIMATIONS DES SLOTS ===

func _animate_slots_cascade_in():
	"""Animation en cascade des slots à l'ouverture"""
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot or not is_instance_valid(slot):
			continue
		
		slot.modulate.a = 0.0
		slot.scale = Vector2(0.8, 0.8)
		
		var row = i / get_grid_columns()
		var delay = row * 0.03
		
		if delay > 0:
			get_tree().create_timer(delay).timeout.connect(_animate_single_slot_in.bind(slot))
		else:
			_animate_single_slot_in(slot)

func _animate_single_slot_in(slot: ClickableSlotUI):
	"""Anime un slot individuel à l'ouverture"""
	if not slot or not is_instance_valid(slot):
		return
	
	var slot_tween = create_tween()
	slot_tween.set_parallel(true)
	
	slot_tween.tween_property(slot, "modulate:a", 1.0, 0.2)
	slot_tween.tween_property(slot, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_slots_cascade_out():
	"""Animation en cascade des slots à la fermeture"""
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot or not is_instance_valid(slot):
			continue
		
		var row = i / get_grid_columns()
		var max_rows = (slots.size() - 1) / get_grid_columns()
		var delay = (max_rows - row) * 0.03
		
		if delay > 0:
			get_tree().create_timer(delay).timeout.connect(_animate_single_slot_out.bind(slot))
		else:
			_animate_single_slot_out(slot)

func _animate_single_slot_out(slot: ClickableSlotUI):
	"""Anime un slot individuel à la fermeture"""
	if not slot or not is_instance_valid(slot):
		return
	
	var slot_tween = create_tween()
	slot_tween.set_parallel(true)
	
	slot_tween.tween_property(slot, "modulate:a", 0.0, 0.2)
	slot_tween.tween_property(slot, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

# === CALLBACKS ANIMATIONS ===

func _on_show_animation_finished():
	"""Callback fin d'animation d'ouverture"""
	is_animating = false
	print("✅ Animation ouverture terminée")

func _on_hide_animation_finished():
	"""Callback fin d'animation de fermeture"""
	visible = false
	is_animating = false
	print("✅ Animation fermeture terminée")

# === MÉTHODES SPÉCIALES ===

func force_update_position():
	"""Force la mise à jour de la position originale"""
	if not visible:
		original_position = position
