# InventoryUI.gd - Interface d'inventaire avec Panel
extends Control

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var panel: Panel = $Panel

var inventory: Inventory
var slot_scenes: Array[Control] = []
var inventory_manager: Node
var selected_slot: int = -1

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	# Configure le TooltipManager pour utiliser cette UI comme parent
	TooltipManager.set_tooltip_parent(self)
	
	if inventory_grid:
		inventory_grid.columns = 9
		create_simple_slots()

func _input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		toggle_inventory()
		get_viewport().set_input_as_handled()

func setup_inventory(inv: Inventory, manager: Node):
	inventory = inv
	inventory_manager = manager
	inventory.slot_changed.connect(_on_slot_changed)
	update_all_slots()

func create_simple_slots():
	if not inventory_grid:
		return
		
	slot_scenes.clear()
	
	for child in inventory_grid.get_children():
		child.queue_free()
	
	for i in range(36):
		# Crée un Panel pour le fond
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(64, 64)
		
		# Style du fond
		var style_box = StyleBoxFlat.new()
		
		slot_panel.add_theme_stylebox_override("panel", style_box)
		
		# Ajoute l'icône
		var icon = TextureRect.new()
		icon.name = "IconTexture"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchors_preset = Control.PRESET_FULL_RECT
		slot_panel.add_child(icon)
		
		# Ajoute le label de quantité
		var quantity = Label.new()
		quantity.name = "QuantityLabel"
		quantity.anchors_preset = Control.PRESET_BOTTOM_RIGHT
		quantity.add_theme_color_override("font_color", Color.WHITE)
		slot_panel.add_child(quantity)
		
		# Attache le script InventorySlot2D
		var script = load("res://scripts/ui/InventorySlot3D.gd")
		slot_panel.set_script(script)
		
		# Connexions pour les clics
		slot_panel.gui_input.connect(_on_slot_input.bind(i))
		
		inventory_grid.add_child(slot_panel)
		slot_scenes.append(slot_panel)

func _on_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_slot_clicked(slot_index)

func _on_slot_clicked(slot_index: int):
	selected_slot = slot_index
	show_item_info(slot_index)

func toggle_inventory():
	visible = !visible
	
	# Cache les tooltips quand l'inventaire se ferme
	if not visible:
		TooltipManager.hide_tooltip()
	
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		selected_slot = -1

func _on_slot_changed(slot_index: int):
	update_slot_visual(slot_index)

func update_slot_visual(slot_index: int):
	if slot_index < 0 or slot_index >= slot_scenes.size():
		return
	
	var slot = inventory.get_slot(slot_index)
	var slot_2d = slot_scenes[slot_index]
	
	if slot.is_empty():
		slot_2d.clear_slot()
	else:
		slot_2d.set_item(slot.item, slot.quantity)

func show_item_info(slot_index: int):
	if not inventory:
		return
		
	var slot = inventory.get_slot(slot_index)
	if slot.is_empty():
		print("Slot vide")
		return
	
	print("=== ", slot.item.name, " ===")
	print(slot.item.description)
	print("Quantité: ", slot.quantity)

func update_all_slots():
	if not inventory:
		return
	
	for i in range(min(inventory.size, slot_scenes.size())):
		update_slot_visual(i)
