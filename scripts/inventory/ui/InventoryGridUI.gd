# scripts/inventory/ui/InventoryGridUI.gd
class_name InventoryGridUI
extends Control

signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)  
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var grid_container: GridContainer = $GridContainer
@export var slot_scene: PackedScene = preload("res://scenes/ui/InventorySlotUI.tscn")
@export var grid_columns: int = 3
@export var grid_rows: int = 3
@export var slot_size: int = 64

var slots: Array[InventorySlotUI] = []

func _ready():
	setup_grid()

func setup_grid():
	if not grid_container:
		push_error("GridContainer non trouvé !")
		return
	
	grid_container.columns = grid_columns
	
	# Calculer la taille totale de la grille
	var total_width = (slot_size * grid_columns) + (4 * (grid_columns - 1))
	var total_height = (slot_size * grid_rows) + (4 * (grid_rows - 1))
	
	custom_minimum_size = Vector2(total_width, total_height)
	
	# Créer les slots
	var total_slots = grid_columns * grid_rows
	
	for i in total_slots:
		create_slot(i)

func create_slot(index: int):
	if not slot_scene:
		push_error("Slot scene non définie !")
		return
	
	var slot_ui = slot_scene.instantiate()
	slot_ui.slot_index = index
	slot_ui.custom_minimum_size = Vector2(slot_size, slot_size)
	
	# Connecter TOUS les signaux y compris le drag
	slot_ui.slot_clicked.connect(_on_slot_clicked)
	slot_ui.slot_right_clicked.connect(_on_slot_right_clicked)
	slot_ui.slot_hovered.connect(_on_slot_hovered)
	slot_ui.drag_started.connect(_on_slot_drag_started)  # NOUVEAU
	
	grid_container.add_child(slot_ui)
	slots.append(slot_ui)

func update_all_slots(slots_data: Array):
	for i in slots.size():
		var slot_ui = slots[i]
		
		if i < slots_data.size():
			slot_ui.update_slot(slots_data[i])
		else:
			slot_ui.clear_slot()

func update_slot(slot_index: int, slot_data: Dictionary):
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].update_slot(slot_data)

func clear_slot(slot_index: int):
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].clear_slot()

func get_slot(slot_index: int) -> InventorySlotUI:
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return null

func set_slot_selected(slot_index: int, selected: bool):
	var slot_ui = get_slot(slot_index)
	if slot_ui:
		slot_ui.set_selected(selected)

# === GESTION DES SIGNAUX ===
func _on_slot_clicked(slot_ui: InventorySlotUI):
	slot_clicked.emit(slot_ui.get_slot_index(), slot_ui)

func _on_slot_right_clicked(slot_ui: InventorySlotUI):
	slot_right_clicked.emit(slot_ui.get_slot_index(), slot_ui)

func _on_slot_hovered(slot_ui: InventorySlotUI):
	slot_hovered.emit(slot_ui.get_slot_index(), slot_ui)

func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	"""Propager le signal de drag vers l'UI parent"""
	slot_drag_started.emit(slot_ui, mouse_pos)
