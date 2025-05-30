# scripts/inventory/ui/InventorySlotUI.gd
class_name InventorySlotUI
extends Control

signal slot_clicked(slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_ui: InventorySlotUI)
signal slot_hovered(slot_ui: InventorySlotUI)
signal drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var background: NinePatchRect = $Background
@onready var item_icon: TextureRect = $ItemIcon  
@onready var quantity_label: Label = $QuantityLabel
@onready var button: Button = $Button

var slot_index: int = -1
var slot_data: Dictionary = {}
var is_selected: bool = false

# Variables pour le drag
var is_mouse_down: bool = false
var mouse_down_pos: Vector2
var drag_threshold: float = 5.0

func _ready():
	button.pressed.connect(_on_button_pressed)
	button.gui_input.connect(_on_button_input)
	button.mouse_entered.connect(_on_button_mouse_entered)
	clear_slot()

func _on_button_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_potential_drag(event.position)
			else:
				_end_potential_drag()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			slot_right_clicked.emit(self)
	
	elif event is InputEventMouseMotion and is_mouse_down:
		_check_drag_threshold(event.position)

func _start_potential_drag(pos: Vector2):
	is_mouse_down = true
	mouse_down_pos = pos

func _end_potential_drag():
	is_mouse_down = false

func _check_drag_threshold(current_pos: Vector2):
	if not is_empty() and mouse_down_pos.distance_to(current_pos) > drag_threshold:
		_start_drag(current_pos)

func _start_drag(mouse_pos: Vector2):
	is_mouse_down = false
	drag_started.emit(self, global_position + mouse_pos)

func _on_button_pressed():
	# Géré maintenant par le système de drag
	slot_clicked.emit(self)

func _on_button_mouse_entered():
	slot_hovered.emit(self)

func update_slot(slot_info: Dictionary):
	slot_data = slot_info
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		
		item_icon.texture = slot_info.get("icon")
		quantity_label.text = str(slot_info.get("quantity", 1))
		quantity_label.visible = slot_info.get("quantity", 1) > 1

func clear_slot():
	item_icon.texture = null
	quantity_label.text = ""
	quantity_label.visible = false
	slot_data = {"is_empty": true}

# === MÉTHODES PUBLIQUES ===
func get_slot_index() -> int:
	return slot_index

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func set_selected(selected: bool):
	is_selected = selected
	if background:
		background.modulate = Color.YELLOW if selected else Color.WHITE

func get_slot_data() -> Dictionary:
	return slot_data

func set_drag_preview_mode(enabled: bool):
	"""Mode aperçu pendant le drag"""
	modulate.a = 0.5 if enabled else 1.0
