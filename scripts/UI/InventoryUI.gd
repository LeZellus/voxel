@tool
extends Control

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var panel: Panel = $Panel

var inventory: Inventory
var inventory_manager: Node
var slot_scenes: Array[Control] = []
var selected_slot: int = -1
var slot_cursor: Control

const INVENTORY_SIZE = 36
const GRID_COLUMNS = 9

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if inventory_grid:
		inventory_grid.columns = GRID_COLUMNS
		_create_slots()
	
	# Créer le curseur
	if not Engine.is_editor_hint():
		_create_slot_cursor()

func _create_slot_cursor():
	slot_cursor = preload("res://scripts/ui/SlotCursor.gd").new()
	panel.add_child(slot_cursor)

func setup_inventory(inv: Inventory, manager: Node):
	inventory = inv
	inventory_manager = manager
	inventory.slot_changed.connect(_on_slot_changed)
	_update_all_slots()

func show_animated():
	visible = true
	await get_tree().process_frame
	
	var estimated_height = (INVENTORY_SIZE / GRID_COLUMNS) * 64 + ((INVENTORY_SIZE / GRID_COLUMNS) * 4) + 32
	UIAnimator.slide_inventory_from_bottom(panel, estimated_height)

func hide_animated():
	if slot_cursor:
		slot_cursor.hide_cursor()
	var tween = UIAnimator.slide_inventory_to_bottom(panel)
	await tween.finished
	visible = false

func _create_slots():
	if Engine.is_editor_hint():
		_create_editor_preview()
	else:
		_create_game_slots()

func _create_editor_preview():
	_clear_existing_slots()
	
	for i in INVENTORY_SIZE:
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.color = Color(0.3, 0.3, 0.3, 0.8)
		slot.name = "PreviewSlot_" + str(i)
		inventory_grid.add_child(slot)

func _create_game_slots():
	_clear_existing_slots()
	
	var slot_scene = preload("res://scenes/ui/InventorySlot2D.tscn")
	
	for i in INVENTORY_SIZE:
		var slot = slot_scene.instantiate()
		if not Engine.is_editor_hint():
			slot.gui_input.connect(_on_slot_input.bind(i))
			slot.mouse_entered.connect(_on_slot_hovered.bind(i))
			slot.mouse_exited.connect(_on_slot_unhovered)
		inventory_grid.add_child(slot)
		slot_scenes.append(slot)

func _on_slot_hovered(slot_index: int):
	if slot_cursor and slot_index < slot_scenes.size():
		slot_cursor.show_on_slot(slot_scenes[slot_index])

func _on_slot_unhovered():
	# Le curseur reste visible mais peut être masqué si on quitte complètement la grille
	pass

func _clear_existing_slots():
	for child in inventory_grid.get_children():
		child.queue_free()
	slot_scenes.clear()

func _on_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_slot(slot_index)

func _select_slot(slot_index: int):
	selected_slot = slot_index
	_show_item_info(slot_index)
	
	if slot_cursor:
		slot_cursor.animate_click()

func _on_slot_changed(slot_index: int):
	_update_slot_visual(slot_index)

func _update_slot_visual(slot_index: int):
	if not _is_valid_slot_index(slot_index):
		return
	
	var slot = inventory.get_slot(slot_index)
	var slot_2d = slot_scenes[slot_index]
	
	if slot.is_empty():
		slot_2d.clear_slot()
	else:
		slot_2d.set_item(slot.item, slot.quantity)

func _show_item_info(slot_index: int):
	if not inventory or not _is_valid_slot_index(slot_index):
		return
		
	var slot = inventory.get_slot(slot_index)
	if slot.is_empty():
		print("Slot vide")
		return
	
	print("=== %s ===" % slot.item.name)
	print(slot.item.description)
	print("Quantité: %d" % slot.quantity)

func _update_all_slots():
	if not inventory:
		return
	
	for i in range(min(inventory.size, slot_scenes.size())):
		_update_slot_visual(i)

func _is_valid_slot_index(index: int) -> bool:
	return index >= 0 and index < slot_scenes.size()
