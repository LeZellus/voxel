class_name InventorySlotUI
extends Control

signal slot_clicked(slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_ui: InventorySlotUI)

@onready var background: NinePatchRect = $Background
@onready var item_icon: TextureRect = $ItemIcon  
@onready var quantity_label: Label = $QuantityLabel
@onready var button: Button = $Button

var slot_index: int = -1
var slot_data: Dictionary = {}

func _ready():
	button.pressed.connect(_on_button_pressed)
	button.gui_input.connect(_on_button_input)
	clear_slot()
	test_ui_slot()

func _on_button_pressed():
	slot_clicked.emit(self)

func _on_button_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(self)

func update_slot(slot_info: Dictionary):
	slot_data = slot_info
	
	if slot_info.is_empty():
		clear_slot()
	else:
		item_icon.texture = slot_info.get("icon")
		quantity_label.text = str(slot_info.quantity)
		quantity_label.visible = slot_info.quantity > 1

func clear_slot():
	item_icon.texture = null
	quantity_label.text = ""
	quantity_label.visible = false
	
func test_ui_slot():
	print("\n🎨 Test UI Slot:")
	
	# Crée une texture temporaire pour test
	var test_texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	test_texture.set_image(image)
	
	# Simule des données de slot
	var slot_data = {
		"is_empty": false,
		"item_name": "Pomme",
		"quantity": 5,
		"icon": test_texture
	}
	
	print("✅ Données de test préparées")
