# scripts/inventory/ui/HotbarUI.gd
class_name HotbarUI
extends Control

# === RÉUTILISE EXACTEMENT LA MÊME LOGIQUE QU'InventoryGridUI ===

signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)  
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var hotbar_grid: Control = $HotbarGrid
@onready var grid_container: GridContainer = $HotbarGrid/GridContainer

@export var slot_scene: PackedScene = preload("res://scenes/ui/InventorySlotUI.tscn")

const HOTBAR_SIZE = 9
const SLOT_SIZE = 64

var slots: Array[InventorySlotUI] = []
var hotbar_container: HotbarContainer
var inventory: Inventory 
var controller: InventoryController
var selected_slot_index: int = 0

func _ready():
	setup_grid()
	
	# IMPORTANT: Forcer l'affichage permanent
	show()
	visible = true
	
	# Positionner correctement en haut de l'écran
	_position_hotbar()

func _position_hotbar():
	"""Position la hotbar en haut centre de l'écran"""
	# Attendre que la taille soit calculée
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	var total_width = 608
	
	# Centrer horizontalement, positionner en haut
	position.x = (viewport_size.x - total_width) / 2
	position.y = 4  # 20px du haut
	size.x = total_width
	size.y = SLOT_SIZE
	
	print("🎯 Hotbar positionnée: %s (taille: %s)" % [position, size])

func setup_grid():
	"""COPIE EXACTE de InventoryGridUI.setup_grid()"""
	clear_existing_slots()
	
	if grid_container:
		grid_container.columns = HOTBAR_SIZE  # 9 au lieu de Constants.GRID_COLUMNS
	
	# Créer seulement 9 slots au lieu de Constants.INVENTORY_SIZE
	for i in HOTBAR_SIZE:
		create_slot(i)
	
	print("✅ Hotbar créée avec %d slots" % HOTBAR_SIZE)

func clear_existing_slots():
	"""COPIE EXACTE de InventoryGridUI.clear_existing_slots()"""
	for slot in slots:
		if slot and is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	for child in grid_container.get_children():
		child.queue_free()

func create_slot(index: int):
	"""COPIE EXACTE de InventoryGridUI.create_slot() avec taille adaptée"""
	if not slot_scene:
		push_error("Slot scene non définie dans HotbarUI !")
		return
	
	var slot_ui = slot_scene.instantiate()
	slot_ui.set_slot_index(index)
	
	# Seule différence : taille des slots
	slot_ui.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot_ui.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# MÊME logique de connexion des signaux
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

# === SETUP HOTBAR (équivalent de setup_inventory) ===

func setup_hotbar(inv: Inventory, ctrl: InventoryController, container: HotbarContainer):
	"""Équivalent de InventoryUI.setup_inventory()"""
	inventory = inv
	controller = ctrl
	hotbar_container = container
	
	if inventory and inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	refresh_ui()
	set_selected_slot(0)

# === MÉTHODES RÉUTILISÉES (copies exactes) ===

func update_all_slots(slots_data: Array):
	"""COPIE EXACTE de InventoryGridUI.update_all_slots()"""
	var max_slots = min(slots.size(), slots_data.size())
	
	for i in max_slots:
		if slots[i] and is_instance_valid(slots[i]):
			slots[i].update_slot(slots_data[i])

func refresh_ui():
	"""COPIE de InventoryUI.refresh_ui() adaptée"""
	if not controller:
		return
	
	var slots_data = []
	for i in HOTBAR_SIZE:
		slots_data.append(controller.get_slot_info(i))
	
	update_all_slots(slots_data)

func get_slot(slot_index: int) -> InventorySlotUI:
	"""COPIE EXACTE de InventoryGridUI.get_slot()"""
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return null

# === SÉLECTION VISUELLE (seule nouveauté) ===

func set_selected_slot(slot_index: int):
	"""Met en surbrillance le slot sélectionné"""
	selected_slot_index = slot_index
	
	# Utilise la méthode set_selected existante d'InventorySlotUI
	for i in slots.size():
		if slots[i]:
			slots[i].set_selected(i == slot_index)

# === GESTION DES SIGNAUX (copies exactes) ===

func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	if hotbar_container:
		hotbar_container.select_slot(slot_index)
	slot_clicked.emit(slot_index, slot_ui)

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	if hotbar_container:
		hotbar_container.use_selected_item()
	slot_right_clicked.emit(slot_index, slot_ui)

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	slot_hovered.emit(slot_index, slot_ui)

func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	slot_drag_started.emit(slot_ui, mouse_pos)

func _on_inventory_changed():
	refresh_ui()
