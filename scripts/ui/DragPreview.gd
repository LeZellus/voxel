# DragPreview.gd
extends Control

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel

func _ready():
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.8
	visible = false

func setup_preview(item: Item, qty: int):
	if item != null:
		icon_texture.texture = item.icon
		quantity_label.text = str(qty) if qty > 1 else ""
	visible = true

func update_position(global_pos: Vector2):
	global_position = global_pos + Vector2(10, 10)

func hide_preview():
	visible = false
