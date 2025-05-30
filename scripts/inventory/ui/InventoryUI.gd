# scripts/inventory/ui/InventoryUI.gd
class_name InventoryUI
extends Control

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $VboxContainer/TitleLabel
@onready var inventory_grid: InventoryGridUI = $VboxContainer/InventoryGrid
@onready var close_button: Button = $VboxContainer/HBoxContainer/CloseButton

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
	
	if close_button:
		close_button.pressed.connect(hide)
	
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
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Configurer la grille
	if inventory_grid:
		var cols = int(sqrt(inventory.get_size()))
		inventory_grid.grid_columns = cols
		inventory_grid.grid_rows = int(ceil(float(inventory.get_size()) / cols))
		inventory_grid.setup_grid()
		
		# Connecter signaux de la grille INCLUANT le drag
		inventory_grid.slot_clicked.connect(_on_slot_clicked)
		inventory_grid.slot_right_clicked.connect(_on_slot_right_clicked)
		inventory_grid.slot_hovered.connect(_on_slot_hovered)
		inventory_grid.slot_drag_started.connect(_on_slot_drag_started)
	
	if title_label:
		title_label.text = inventory.name
	
	refresh_ui()

func refresh_ui():
	if not is_setup or not inventory_grid:
		return
	
	var slots_data = []
	for i in inventory.get_size():
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
	
	# Optionnel: feedback visuel global
	if AudioManager:
		AudioManager.play_ui_sound("ui_drag_start")

func _on_drag_completed(from_slot: int, to_slot: int):
	"""Callback quand un drag se termine avec succès"""
	print("🎯 Drag completed: ", from_slot, " → ", to_slot)
	
	if controller:
		var success = controller.move_item(from_slot, to_slot)
		
		if success:
			if AudioManager:
				AudioManager.play_ui_sound("ui_drag_success")
		else:
			if AudioManager:
				AudioManager.play_ui_sound("ui_drag_fail")

func _on_drag_cancelled():
	"""Callback quand un drag est annulé"""
	print("🎯 Drag cancelled")
	
	if AudioManager:
		AudioManager.play_ui_sound("ui_drag_cancel")

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

func get_inventory_stats() -> String:
	if not inventory:
		return "Aucun inventaire"
	
	return "%d/%d slots utilisés" % [inventory.get_used_slots_count(), inventory.get_size()]
