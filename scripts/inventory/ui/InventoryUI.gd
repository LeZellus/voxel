# scripts/inventory/ui/InventoryUI.gd - VERSION AVEC ANIMATION GLISSANTE
class_name InventoryUI
extends Control

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $MarginContainer/CenterContainer/VboxContainer/TitleLabel
@onready var inventory_grid: InventoryGridUI = $MarginContainer/CenterContainer/VboxContainer/InventoryGrid

var inventory: Inventory
var controller: InventoryController
var drag_manager: DragDropManager
var is_setup: bool = false

# Animation
var tween: Tween
var animation_duration: float = 0.4
var slide_distance: float = 0.0  # Calculé automatiquement

func _ready():
	setup_drag_manager()
	setup_ui()
	# Démarrer caché et positionné
	call_deferred("setup_animation_positions")

func setup_animation_positions():
	"""Configure les positions pour l'animation de glissement"""
	# S'assurer que la taille est calculée
	if size.y <= 0:
		await get_tree().process_frame
		await get_tree().process_frame  # Double attente pour être sûr
	
	# Forcer le recalcul de la taille si nécessaire
	if size.y <= 0:
		custom_minimum_size = Vector2(640, 400)  # Taille de secours
		await get_tree().process_frame
	
	# Position finale : 4px du bas
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	
	# Calculer la distance de glissement AVANT de positionner
	slide_distance = size.y + 50  # Plus de marge pour l'effet
	
	# Position finale (visible)
	var final_position = -size.y - 4
	
	# Position de départ (cachée) - PLUS BAS que l'écran
	var hidden_position = final_position + slide_distance
	
	# Démarrer en position cachée
	offset_top = hidden_position
	visible = false  # S'assurer qu'on démarre caché
	
	print("🎬 Animation setup - Taille: ", size, " Final: ", final_position, " Caché: ", hidden_position)

func setup_drag_manager():
	drag_manager = DragDropManager.new()
	add_child(drag_manager)
	
	drag_manager.drag_started.connect(_on_drag_started)
	drag_manager.drag_completed.connect(_on_drag_completed)
	drag_manager.drag_cancelled.connect(_on_drag_cancelled)

func setup_ui():
	set_process_unhandled_input(true)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_animated()
		get_viewport().set_input_as_handled()

func setup_inventory(inv: Inventory, ctrl: InventoryController):
	inventory = inv
	controller = ctrl
	is_setup = true
	
	if inventory and inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	if inventory_grid:
		setup_inventory_grid()
		drag_manager.set_inventory_grid(inventory_grid)
	
	if title_label:
		title_label.text = inventory.name if inventory else "Inventaire"
	
	refresh_ui()

func setup_inventory_grid():
	inventory_grid.grid_columns = Constants.GRID_COLUMNS
	inventory_grid.grid_rows = Constants.GRID_ROWS
	inventory_grid.setup_grid()
	
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

# === ANIMATIONS OPTIMISÉES ===
func show_animated():
	"""Animation de glissement depuis le bas"""
	print("🎬 Début show_animated - Taille: ", size, " Position actuelle: ", offset_top)
	
	if tween and tween.is_valid():
		tween.kill()
	
	# Positions calculées
	var final_position = -size.y - 4  # Position finale : 4px du bas
	var hidden_position = final_position + slide_distance  # Position cachée
	
	print("🎬 Positions - Final: ", final_position, " Caché: ", hidden_position)
	
	# S'assurer qu'on démarre de la bonne position
	offset_top = hidden_position
	visible = true
	
	# Créer l'animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animation de glissement
	tween.tween_property(self, "offset_top", final_position, animation_duration)
	
	# Animation de fade en parallèle
	modulate = Color(1, 1, 1, 0.0)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, animation_duration * 0.6)
	
	print("🎬 Animation lancée vers position: ", final_position)

func hide_animated():
	"""Animation de glissement vers le bas"""
	print("🎬 Début hide_animated")
	
	if tween and tween.is_valid():
		tween.kill()
	
	# Position cachée = position actuelle + slide_distance
	var hidden_position = (-size.y - 4) + slide_distance
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animation de glissement vers le bas
	tween.tween_property(self, "offset_top", hidden_position, animation_duration * 0.7)
	
	# Fade out en parallèle
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration * 0.5)
	
	# Masquer à la fin
	tween.tween_callback(func(): 
		visible = false
		print("🎬 Animation terminée - UI masquée")
	)

# === GESTION DU DRAG & DROP ===
func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	if not controller or slot_ui.is_empty():
		return
	drag_manager.start_drag(slot_ui, mouse_pos)

func _on_drag_started(slot_index: int):
	_play_ui_sound("ui_drag_start")

func _on_drag_completed(from_slot: int, to_slot: int):
	if controller:
		var success = controller.move_item(from_slot, to_slot)
		_play_ui_sound("ui_drag_success" if success else "ui_drag_fail")

func _on_drag_cancelled():
	_play_ui_sound("ui_drag_cancel")

# === GESTION DES CLICS ===
func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	pass

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	pass

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	pass

func _on_inventory_changed():
	refresh_ui()

# === UTILITAIRES ===
func _play_ui_sound(sound_name: String):
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

func get_inventory_stats() -> String:
	if not inventory:
		return "Aucun inventaire"
	return "%d/%d slots utilisés" % [inventory.get_used_slots_count(), inventory.get_size()]
