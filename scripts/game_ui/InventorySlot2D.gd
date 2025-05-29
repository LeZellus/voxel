# InventorySlot2D.gd
extends Control
signal drag_started(slot: Control)
signal drag_ended()

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel

var item_data: Item
var quantity: int = 0
var tooltip_manager: Node
var inventory_ui: Control

var is_dragging: bool = false
var drag_start_position: Vector2
var min_drag_distance: float = 5.0

func _ready():
	quantity_label.text = ""
	theme = preload("res://assets/resources/game_theme.tres")
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func setup_slot(inventory_reference: Control):
	inventory_ui = inventory_reference

func is_inventory_active() -> bool:
	return inventory_ui != null and inventory_ui.visible

func _on_hover():
	if not is_inventory_active():
		return
	
	AudioManager.play_ui_sound("ui_click_4")
	add_theme_stylebox_override("panel", theme.get_stylebox("panel_hover", "Panel"))

func _on_unhover():
	if not is_inventory_active():
		return
	
	add_theme_stylebox_override("panel", theme.get_stylebox("panel", "Panel"))

func handle_input(event: InputEvent):
	if not is_inventory_active():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				AudioManager.play_ui_sound("ui_click_6")
				_on_mouse_down(event)
			else:
				_on_mouse_up(event)
	elif event is InputEventMouseMotion:
		_on_mouse_drag(event)

func set_item(item: Item, qty: int = 1):
	item_data = item
	quantity = qty
	
	if item == null or qty <= 0:
		icon_texture.texture = null
		quantity_label.text = ""
		return
	
	icon_texture.texture = item.icon
	
	if qty > 1:
		quantity_label.text = str(qty)
	else:
		quantity_label.text = ""

func clear_slot():
	set_item(null, 0)

func _on_mouse_down(_event: InputEventMouseButton):
	if item_data != null:
		drag_start_position = get_global_mouse_position()

func _on_mouse_up(_event: InputEventMouseButton):
	if is_dragging:
		drag_ended.emit()
	is_dragging = false
	drag_start_position = Vector2.ZERO

func _on_mouse_drag(event: InputEventMouseMotion):
	if item_data != null and drag_start_position != Vector2.ZERO and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var current_global_pos = get_global_mouse_position()
		
		if not is_dragging:
			var distance = current_global_pos.distance_to(drag_start_position)
			
			if distance > min_drag_distance:
				is_dragging = true
				drag_started.emit(self)

func has_item() -> bool:
	return item_data != null and quantity > 0

func get_item_data() -> Item:
	return item_data

func get_quantity() -> int:
	return quantity
