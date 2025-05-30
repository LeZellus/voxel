# scripts/inventory/ui/InventorySlotUI.gd - VERSION CORRIGÉE
class_name InventorySlotUI
extends Control

# Signaux corrigés - émettre les bons paramètres
signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var background: NinePatchRect = $Background
@onready var item_icon: TextureRect = $ItemIcon  
@onready var quantity_label: Label = $QuantityLabel
@onready var button: Button = $Button

var slot_index: int = -1
var slot_data: Dictionary = {}
var is_selected: bool = false

# Variables pour le drag - simplifiées
var is_mouse_down: bool = false
var mouse_down_pos: Vector2
var drag_threshold: float = 5.0

func _ready():
	if button:
		button.pressed.connect(_on_button_pressed)
		button.gui_input.connect(_on_button_input)
		button.mouse_entered.connect(_on_button_mouse_entered)
	clear_slot()

func _on_button_input(event: InputEvent):
	if not event is InputEventMouseButton:
		return
		
	var mouse_event = event as InputEventMouseButton
	
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_event.pressed:
			_start_potential_drag(mouse_event.position)
		else:
			_end_potential_drag()
	
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		slot_right_clicked.emit(slot_index, self)  # CORRIGÉ

func _start_potential_drag(pos: Vector2):
	if is_empty():
		return
	is_mouse_down = true
	mouse_down_pos = pos

func _end_potential_drag():
	is_mouse_down = false

func _on_button_pressed():
	# Émission corrigée des signaux
	slot_clicked.emit(slot_index, self)  # CORRIGÉ

func _on_button_mouse_entered():
	slot_hovered.emit(slot_index, self)  # CORRIGÉ

func update_slot(slot_info: Dictionary):
	slot_data = slot_info
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		if item_icon:
			item_icon.texture = slot_info.get("icon")
		if quantity_label:
			var qty = slot_info.get("quantity", 1)
			quantity_label.text = str(qty)
			quantity_label.visible = qty > 1

func clear_slot():
	if item_icon:
		item_icon.texture = null
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
	slot_data = {"is_empty": true}

# === MÉTHODES PUBLIQUES ===
func get_slot_index() -> int:
	return slot_index

func set_slot_index(index: int):
	slot_index = index

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
