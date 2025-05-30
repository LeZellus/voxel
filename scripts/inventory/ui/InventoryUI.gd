# scripts/inventory/ui/InventoryUI.gd - VERSION CORRIGÉE
class_name InventoryUI
extends Control

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $VboxContainer/TitleLabel
@onready var inventory_grid: InventoryGridUI = $VboxContainer/InventoryGrid

var inventory: Inventory
var controller: InventoryController
var drag_manager: DragDropManager
var is_setup: bool = false

func _ready():
	visible = false
	setup_drag_manager()
	setup_ui()

func setup_drag_manager():
	drag_manager = DragDropManager.new()
	add_child(drag_manager)
	
	# Connecter les signaux du drag manager
	drag_manager.drag_started.connect(_on_drag_started)
	drag_manager.drag_completed.connect(_on_drag_completed)
	drag_manager.drag_cancelled.connect(_on_drag_cancelled)

func setup_ui():
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	set_process_unhandled_input(true)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()

func setup_inventory(inv: Inventory, ctrl: InventoryController):
	inventory = inv
	controller = ctrl
	is_setup = true
	
	# Connecter les signaux
	if inventory and inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Configurer la grille
	if inventory_grid:
		setup_inventory_grid()
		
		# IMPORTANT : Donner la référence de la grille au drag manager
		drag_manager.set_inventory_grid(inventory_grid)
	
	if title_label:
		title_label.text = inventory.name if inventory else "Inventaire"
	
	refresh_ui()

func setup_inventory_grid():
	inventory_grid.grid_columns = Constants.GRID_COLUMNS
	inventory_grid.grid_rows = Constants.GRID_ROWS
	
	# Reconfigurer la grille
	inventory_grid.setup_grid()
	
	# Connecter les signaux - VÉRIFIER QU'ILS EXISTENT
	if inventory_grid.has_signal("slot_clicked"):
		inventory_grid.slot_clicked.connect(_on_slot_clicked)
	if inventory_grid.has_signal("slot_right_clicked"):
		inventory_grid.slot_right_clicked.connect(_on_slot_right_clicked)
	if inventory_grid.has_signal("slot_hovered"):
		inventory_grid.slot_hovered.connect(_on_slot_hovered)
	if inventory_grid.has_signal("slot_drag_started"):
		inventory_grid.slot_drag_started.connect(_on_slot_drag_started)

func refresh_ui():
	if not is_setup or not inventory_grid or not controller:
		return
	
	var slots_data = []
	for i in Constants.INVENTORY_SIZE:
		slots_data.append(controller.get_slot_info(i))
	
	inventory_grid.update_all_slots(slots_data)

func show_animated():
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_animated():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(hide)

# === GESTION DU DRAG & DROP ===
func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	"""Démarrer un drag depuis un slot"""
	if not controller or slot_ui.is_empty():
		return
	
	drag_manager.start_drag(slot_ui, mouse_pos)

func _on_drag_started(slot_index: int):
	"""Callback quand un drag commence"""
	print("🎯 Drag started from slot ", slot_index)
	_play_ui_sound("ui_drag_start")

func _on_drag_completed(from_slot: int, to_slot: int):
	"""Callback quand un drag se termine avec succès"""
	print("🎯 Drag completed: ", from_slot, " → ", to_slot)
	
	if controller:
		var success = controller.move_item(from_slot, to_slot)
		
		if success:
			_play_ui_sound("ui_drag_success")
		else:
			_play_ui_sound("ui_drag_fail")

func _on_drag_cancelled():
	"""Callback quand un drag est annulé"""
	print("🎯 Drag cancelled")
	_play_ui_sound("ui_drag_cancel")

# === GESTION DES CLICS (fallback) ===
func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	"""Gestion des clics simples (sans drag)"""
	print("🖱️ Simple click on slot ", slot_index)

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	print("🖱️ Right click on slot ", slot_index)
	# TODO: Menu contextuel

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	# TODO: Tooltip
	pass

func _on_inventory_changed():
	refresh_ui()

# === UTILITAIRES ===
func _play_ui_sound(sound_name: String):
	"""Version sécurisée pour jouer des sons"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

func get_inventory_stats() -> String:
	if not inventory:
		return "Aucun inventaire"
	
	return "%d/%d slots utilisés" % [inventory.get_used_slots_count(), inventory.get_size()]
