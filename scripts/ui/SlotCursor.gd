# SlotCursor.gd
extends Control

var tween: Tween
var corner_size: int = 12
var border_width: int = 2

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ne pas intercepter les clics
	z_index = 100

func _draw():
	if not visible:
		return
	
	var rect = Rect2(Vector2.ZERO, size)
	var color = Color.html("#577277")
	
	# Coin haut-gauche
	draw_rect(Rect2(0, 0, corner_size, border_width), color)
	draw_rect(Rect2(0, 0, border_width, corner_size), color)
	
	# Coin haut-droite
	draw_rect(Rect2(size.x - corner_size, 0, corner_size, border_width), color)
	draw_rect(Rect2(size.x - border_width, 0, border_width, corner_size), color)
	
	# Coin bas-gauche
	draw_rect(Rect2(0, size.y - border_width, corner_size, border_width), color)
	draw_rect(Rect2(0, size.y - corner_size, border_width, corner_size), color)
	
	# Coin bas-droite
	draw_rect(Rect2(size.x - corner_size, size.y - border_width, corner_size, border_width), color)
	draw_rect(Rect2(size.x - border_width, size.y - corner_size, border_width, corner_size), color)

func show_on_slot(target_control: Control):
	visible = true
	size = target_control.size
	
	# Définir le pivot au centre pour l'animation de scale
	pivot_offset = size / 2
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "global_position", target_control.global_position, 0.15)

func hide_cursor():
	visible = false
	
func animate_click():
	if not visible:
		return
		
	# Créer un tween séparé pour l'animation de clic
	var click_tween = create_tween()
	click_tween.set_parallel(true)  # Permet plusieurs animations simultanées
	
	# Animation de scale (pulse effect)
	click_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	click_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.1)
