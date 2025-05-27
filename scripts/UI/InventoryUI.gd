@tool
extends Control

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var panel: Panel = $Panel

var inventory: Inventory
var inventory_manager: Node
var slot_scenes: Array[Control] = []
var selected_slot: int = -1
var slot_cursor: Control

# Variables pour le drag and drop
var drag_preview: Control
var dragged_slot_index: int = -1
var is_dragging: bool = false

const INVENTORY_SIZE = 36
const GRID_COLUMNS = 9

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if inventory_grid:
		inventory_grid.columns = GRID_COLUMNS
		create_slots()
	
	if not Engine.is_editor_hint():
		create_slot_cursor()
		create_drag_preview()

func create_drag_preview():
	var drag_preview_scene = preload("res://scenes/ui/DragPreview.tscn")
	if drag_preview_scene:
		drag_preview = drag_preview_scene.instantiate()
		drag_preview.visible = false
		panel.add_child(drag_preview)

func create_slot_cursor():
	slot_cursor = preload("res://scripts/ui/SlotCursor.gd").new()
	panel.add_child(slot_cursor)

func setup_inventory(inv: Inventory, manager: Node):
	inventory = inv
	inventory_manager = manager
	inventory.slot_changed.connect(_on_slot_changed)
	update_all_slots()

func show_animated():
	visible = true
	await get_tree().process_frame
	
	var estimated_height = (INVENTORY_SIZE / GRID_COLUMNS) * 64 + ((INVENTORY_SIZE / GRID_COLUMNS) * 4) + 32
	UIAnimator.slide_inventory_from_bottom(panel, estimated_height)

func hide_animated():
	if slot_cursor:
		slot_cursor.hide_cursor()
	if is_dragging:
		_cancel_drag()
	
	var tween = UIAnimator.slide_inventory_to_bottom(panel)
	await tween.finished
	visible = false

func create_slots():
	if Engine.is_editor_hint():
		create_editor_preview()
	else:
		create_game_slots()

func create_editor_preview():
	clear_existing_slots()
	
	for i in INVENTORY_SIZE:
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.color = Color(0.3, 0.3, 0.3, 0.8)
		slot.name = "PreviewSlot_" + str(i)
		inventory_grid.add_child(slot)

func create_game_slots():
	clear_existing_slots()
	
	var slot_scene = preload("res://scenes/ui/InventorySlot2D.tscn")
	print("Slot scene loaded: ", slot_scene != null)
	
	for i in INVENTORY_SIZE:
		var slot = slot_scene.instantiate()
		print("Slot ", i, " created: ", slot != null)
		
		if not Engine.is_editor_hint():
			slot.gui_input.connect(_on_slot_input.bind(i))
			slot.mouse_entered.connect(_on_slot_hovered.bind(i))
			slot.mouse_exited.connect(_on_slot_unhovered)
			
			slot.drag_started.connect(_on_slot_drag_started.bind(i))
			slot.drag_ended.connect(_on_slot_drag_ended)
			
		inventory_grid.add_child(slot)
		slot_scenes.append(slot)
	
	print("Total slots created: ", slot_scenes.size())

func _on_slot_drag_started(slot: Control, slot_index: int):
	if slot.has_item():
		is_dragging = true
		dragged_slot_index = slot_index
		
		if drag_preview:
			drag_preview.setup_preview(slot.get_item_data(), slot.get_quantity())
		
		slot.modulate.a = 0.5

func _on_slot_drag_ended():
	if is_dragging:
		_handle_drop()

func _handle_drop():
	var mouse_pos = get_global_mouse_position()
	var target_slot_index = _find_slot_at_position(mouse_pos)
	
	if target_slot_index != -1 and target_slot_index != dragged_slot_index:
		_swap_slots(dragged_slot_index, target_slot_index)
	
	_cancel_drag()

func _find_slot_at_position(global_pos: Vector2) -> int:
	for i in range(slot_scenes.size()):
		var slot = slot_scenes[i]
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(global_pos):
			return i
	return -1

func _swap_slots(from_index: int, to_index: int):
	if not inventory:
		return
	
	var from_slot = inventory.get_slot(from_index)
	var to_slot = inventory.get_slot(to_index)
	
	var temp_item = from_slot.item
	var temp_quantity = from_slot.quantity
	
	from_slot.item = to_slot.item
	from_slot.quantity = to_slot.quantity
	
	to_slot.item = temp_item
	to_slot.quantity = temp_quantity
	
	inventory.slot_changed.emit(from_index)
	inventory.slot_changed.emit(to_index)

func _cancel_drag():
	is_dragging = false
	dragged_slot_index = -1
	
	if drag_preview:
		drag_preview.hide_preview()
	
	for slot in slot_scenes:
		slot.modulate.a = 1.0

func _process(_delta):
	if is_dragging and drag_preview:
		drag_preview.update_position(get_global_mouse_position())

func _on_slot_hovered(slot_index: int):
	if slot_cursor and slot_index < slot_scenes.size():
		slot_cursor.show_on_slot(slot_scenes[slot_index])

func _on_slot_unhovered():
	pass

func clear_existing_slots():
	for child in inventory_grid.get_children():
		child.queue_free()
	slot_scenes.clear()

func _on_slot_input(event: InputEvent, slot_index: int):
	var slot = slot_scenes[slot_index]
	slot.handle_input(event)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_dragging:
			select_slot(slot_index)

func select_slot(slot_index: int):
	selected_slot = slot_index
	show_item_info(slot_index)
	
	if slot_cursor:
		slot_cursor.animate_click()

func _on_slot_changed(slot_index: int):
	update_slot_visual(slot_index)

func update_slot_visual(slot_index: int):
	if not is_valid_slot_index(slot_index):
		return
	
	var slot = inventory.get_slot(slot_index)
	var slot_2d = slot_scenes[slot_index]
	
	if slot.is_empty():
		slot_2d.clear_slot()
	else:
		slot_2d.set_item(slot.item, slot.quantity)

func show_item_info(slot_index: int):
	if not inventory or not is_valid_slot_index(slot_index):
		return
		
	var slot = inventory.get_slot(slot_index)
	if slot.is_empty():
		print("Slot vide")
		return
	
	print("=== %s ===" % slot.item.name)
	print(slot.item.description)
	print("Quantité: %d" % slot.quantity)

func update_all_slots():
	if not inventory:
		return
	
	for i in range(min(inventory.size, slot_scenes.size())):
		update_slot_visual(i)

func is_valid_slot_index(index: int) -> bool:
	return index >= 0 and index < slot_scenes.size()
