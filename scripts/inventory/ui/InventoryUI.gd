# scripts/inventory/ui/InventoryUI.gd
class_name InventoryUI
extends Control

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $VboxContainer/TitleLabel
@onready var inventory_grid: InventoryGridUI = $VboxContainer/InventoryGrid
@onready var close_button: Button = $VboxContainer/HBoxContainer/CloseButton

var inventory: Inventory
var controller: InventoryController
var is_setup: bool = false

func _ready():
	visible = false
	setup_ui()

func setup_ui():
	# Configuration de base
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Connecter le bouton fermer
	if close_button:
		close_button.pressed.connect(hide)
	
	# Gestion de l'échappement
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
		# Calculer colonnes basé sur la taille
		var cols = int(sqrt(inventory.get_size()))
		inventory_grid.grid_columns = cols
		inventory_grid.grid_rows = int(ceil(float(inventory.get_size()) / cols))
		inventory_grid.setup_grid()
		
		# Connecter signaux de la grille
		inventory_grid.slot_clicked.connect(_on_slot_clicked)
		inventory_grid.slot_right_clicked.connect(_on_slot_right_clicked)
		inventory_grid.slot_hovered.connect(_on_slot_hovered)
	
	# Mettre à jour le titre
	if title_label:
		title_label.text = inventory.name
	
	# Mise à jour initiale
	refresh_ui()

func refresh_ui():
	if not is_setup or not inventory_grid:
		return
	
	# Récupérer toutes les données des slots
	var slots_data = []
	for i in inventory.get_size():
		slots_data.append(controller.get_slot_info(i))
	
	# Mettre à jour la grille
	inventory_grid.update_all_slots(slots_data)

func show_animated():
	visible = true
	# Animation d'apparition simple
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_animated():
	# Animation de disparition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(hide)

# === GESTION DES INTERACTIONS ===
func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	if not controller:
		return
	
	# Gestion simple : commencer un drag ou compléter un drag
	var interaction_manager = controller.interaction_manager
	
	if interaction_manager.is_interacting():
		# Compléter l'interaction en cours
		interaction_manager.complete_drag(slot_index)
	else:
		# Commencer une nouvelle interaction
		interaction_manager.start_drag(slot_index)

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	print("🖱️ Clic droit sur slot ", slot_index)
	# TODO: Menu contextuel

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	# TODO: Tooltip
	pass

func _on_inventory_changed():
	refresh_ui()

# === UTILS ===
func get_inventory_stats() -> String:
	if not inventory:
		return "Aucun inventaire"
	
	return "%d/%d slots utilisés" % [inventory.get_used_slots_count(), inventory.get_size()]
