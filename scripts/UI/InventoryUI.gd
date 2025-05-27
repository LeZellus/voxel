# InventoryUI.gd - Interface d'inventaire avec icônes 2D
extends Control

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var panel: Panel = $Panel

var inventory: Inventory
var slot_scenes: Array[Control] = []
var inventory_manager: Node
var selected_slot: int = -1
var tooltip_panel: Panel

# Utilisez votre scène InventorySlot2D
var slot_2d_scene: PackedScene = preload("res://scenes/ui/InventorySlot3D.tscn")

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	
	create_tooltip()
	
	if inventory_grid:
		inventory_grid.columns = 9
		create_simple_slots()

func create_tooltip():
	tooltip_panel = Panel.new()
	tooltip_panel.visible = false
	tooltip_panel.z_index = 100
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color.WHITE
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.name = "TooltipLabel"
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 12)
	tooltip_panel.add_child(label)
	
	get_tree().current_scene.add_child(tooltip_panel)

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
		var slot_2d = slot_2d_scene.instantiate()
		slot_2d.custom_minimum_size = Vector2(64, 64)
		
		# Style de bordure pour la case
		var style = StyleBoxFlat.new()
		style.border_width_left = 1
		style.border_width_top = 1  
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color.GRAY
		style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
		slot_2d.add_theme_stylebox_override("panel", style)
		
		# Connexions pour les clics/survol
		slot_2d.gui_input.connect(_on_slot_input.bind(i))
		slot_2d.mouse_entered.connect(_on_slot_hover.bind(i))
		slot_2d.mouse_exited.connect(_on_slot_unhover.bind(i))
		
		inventory_grid.add_child(slot_2d)
		slot_scenes.append(slot_2d)

func _on_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_slot_clicked(slot_index)

func _on_slot_clicked(slot_index: int):
	selected_slot = slot_index
	show_item_info(slot_index)

func _on_slot_hover(slot_index: int):
	if not inventory:
		return
		
	var slot = inventory.get_slot(slot_index)
	if slot.is_empty():
		return
	
	var tooltip_label = tooltip_panel.get_node("TooltipLabel")
	var text = slot.item.name + "\n" + slot.item.description + "\nQuantité: " + str(slot.quantity)
	tooltip_label.text = text
	
	var mouse_pos = get_global_mouse_position()
	tooltip_panel.position = mouse_pos + Vector2(10, 10)
	tooltip_panel.size = Vector2(200, 80)
	tooltip_panel.visible = true

func _on_slot_unhover(slot_index: int):
	tooltip_panel.visible = false

func toggle_inventory():
	visible = !visible
	
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
