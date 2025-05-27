# DragPreview.gd
extends Control

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel
var shake_tween: Tween

func _ready():
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.8
	visible = false
	set_deferred("custom_minimum_size", Vector2(64, 64))
	set_deferred("size", Vector2(64, 64))

func setup_preview(item: Item, qty: int):
	if item != null:
		icon_texture.texture = item.icon
		quantity_label.text = str(qty) if qty > 1 else ""
	visible = true
	_start_shake()

func _start_shake():
	if shake_tween:
		shake_tween.kill()
	
	shake_tween = create_tween()
	shake_tween.set_loops()
	shake_tween.tween_method(_shake_icon, 0.0, PI * 2, 0.1)

func _shake_icon(angle: float):
	var shake_offset = Vector2(sin(angle) * 2, cos(angle * 1.5) * 1.5)
	icon_texture.position = shake_offset

func update_position(global_pos: Vector2):
	global_position = global_pos - Vector2(32, 32)

func hide_preview():
	if shake_tween:
		shake_tween.kill()
	icon_texture.position = Vector2.ZERO
	visible = false
