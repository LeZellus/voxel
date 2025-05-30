# scripts/inventory/ui/InventoryGridUI.gd - VERSION CORRIGÉE
class_name InventoryGridUI
extends Control

signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)  
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var grid_container: GridContainer = $GridContainer
@export var slot_scene: PackedScene = preload("res://scenes/ui/InventorySlotUI.tscn")

var grid_columns: int = Constants.GRID_COLUMNS
var grid_rows: int = Constants.GRID_ROWS

@export var slot_size: int = 64

var slots: Array[InventorySlotUI] = []

func _ready():
	if grid_container:
		setup_grid()
	else:
		print("❌ GridContainer non trouvé dans InventoryGridUI")

func setup_grid():
	# Nettoyer les slots existants
	clear_existing_slots()
	
	for i in Constants.INVENTORY_SIZE:
		create_slot(i)

func clear_existing_slots():
	"""Nettoie les slots existants avant d'en créer de nouveaux"""
	for slot in slots:
		if slot and is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Nettoyer aussi les enfants du grid_container
	for child in grid_container.get_children():
		child.queue_free()

func create_slot(index: int):
	if not slot_scene:
		push_error("Slot scene non définie dans InventoryGridUI !")
		return
	
	var slot_ui = slot_scene.instantiate()
	slot_ui.set_slot_index(index)  # Utiliser la méthode setter
	
	# Connecter TOUS les signaux avec vérification
	if slot_ui.has_signal("slot_clicked"):
		slot_ui.slot_clicked.connect(_on_slot_clicked)
	if slot_ui.has_signal("slot_right_clicked"):
		slot_ui.slot_right_clicked.connect(_on_slot_right_clicked)
	if slot_ui.has_signal("slot_hovered"):
		slot_ui.slot_hovered.connect(_on_slot_hovered)
	if slot_ui.has_signal("drag_started"):
		slot_ui.drag_started.connect(_on_slot_drag_started)
	
	grid_container.add_child(slot_ui)
	slots.append(slot_ui)

func update_all_slots(slots_data: Array):
	"""Met à jour tous les slots avec les nouvelles données"""
	var max_slots = min(slots.size(), slots_data.size())
	
	for i in max_slots:
		if slots[i] and is_instance_valid(slots[i]):
			slots[i].update_slot(slots_data[i])
	
	# Nettoyer les slots supplémentaires
	for i in range(max_slots, slots.size()):
		if slots[i] and is_instance_valid(slots[i]):
			slots[i].clear_slot()

func update_slot(slot_index: int, slot_data: Dictionary):
	"""Met à jour un slot spécifique"""
	if slot_index >= 0 and slot_index < slots.size():
		var slot = slots[slot_index]
		if slot and is_instance_valid(slot):
			slot.update_slot(slot_data)

func clear_slot(slot_index: int):
	"""Vide un slot spécifique"""
	if slot_index >= 0 and slot_index < slots.size():
		var slot = slots[slot_index]
		if slot and is_instance_valid(slot):
			slot.clear_slot()

func get_slot(slot_index: int) -> InventorySlotUI:
	"""Récupère un slot par son index"""
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return null

func set_slot_selected(slot_index: int, selected: bool):
	"""Sélectionne/désélectionne un slot"""
	var slot_ui = get_slot(slot_index)
	if slot_ui:
		slot_ui.set_selected(selected)

func get_slot_count() -> int:
	"""Retourne le nombre total de slots"""
	return slots.size()

# === GESTION DES SIGNAUX ===
func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	slot_clicked.emit(slot_index, slot_ui)

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	slot_right_clicked.emit(slot_index, slot_ui)

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	slot_hovered.emit(slot_index, slot_ui)

func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	"""Propager le signal de drag vers l'UI parent"""
	slot_drag_started.emit(slot_ui, mouse_pos)
