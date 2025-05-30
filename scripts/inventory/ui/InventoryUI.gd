# scripts/inventory/ui/InventoryUI.gd - VERSION CORRIGÉE
class_name InventoryUI
extends Control

@onready var background: NinePatchRect = $Background
@onready var title_label: Label = $MarginContainer/CenterContainer/VboxContainer/TitleLabel
@onready var inventory_grid: InventoryGridUI = $MarginContainer/CenterContainer/VboxContainer/InventoryGrid

var inventory: Inventory
var controller: InventoryController
var drag_manager: DragDropManager
var is_setup: bool = false

# Animation - Variables simplifiées
var tween: Tween
var animation_duration: float = 0.4

func _ready():
	setup_drag_manager()
	setup_ui()
	# IMPORTANT : Forcer l'UI à être cachée au démarrage
	hide_immediately()

func hide_immediately():
	"""Cache immédiatement l'UI sans animation"""
	visible = false
	# Position hors écran (en bas)
	position.y = get_viewport().get_visible_rect().size.y + size.y

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

# === ANIMATIONS SIMPLIFIÉES ET CORRIGÉES ===
func show_animated():
	"""Animation de glissement depuis le bas - VERSION CORRIGÉE"""
	print("🎬 Début show_animated")
	
	if tween and tween.is_valid():
		tween.kill()
	
	# S'assurer que la taille est calculée
	if size.y <= 0:
		await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position finale : centré horizontalement, 20px du bas
	var final_x = (viewport_size.x - size.x) / 2
	var final_y = viewport_size.y - size.y - 4
	
	# Position de départ : même X, mais complètement en bas (cachée)
	var start_x = final_x
	var start_y = viewport_size.y + 50  # 50px en dessous de l'écran
	
	print("🎬 Positions - Start: (", start_x, ", ", start_y, ") Final: (", final_x, ", ", final_y, ")")
	
	# Positionner au point de départ
	position = Vector2(start_x, start_y)
	visible = true
	modulate = Color(1, 1, 1, 0.8)  # Légèrement transparent au début
	
	# Créer l'animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animation de glissement
	tween.tween_property(self, "position", Vector2(final_x, final_y), animation_duration)
	
	# Animation de fade en parallèle
	tween.parallel().tween_property(self, "modulate", Color.WHITE, animation_duration * 0.6)
	
	print("🎬 Animation de montée lancée")

func hide_animated():
	"""Animation de glissement vers le bas - VERSION CORRIGÉE"""
	print("🎬 Début hide_animated")
	
	if tween and tween.is_valid():
		tween.kill()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position finale : même X, complètement en bas (cachée)
	var final_x = position.x
	var final_y = viewport_size.y + 50  # 50px en dessous de l'écran
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animation de glissement vers le bas
	tween.tween_property(self, "position", Vector2(final_x, final_y), animation_duration * 0.7)
	
	# Fade out en parallèle
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration * 0.5)
	
	# Masquer à la fin
	tween.tween_callback(func(): 
		visible = false
		print("🎬 Animation de descente terminée - UI masquée")
	)

# === GESTION DU DRAG & DROP ===
func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	if not controller or slot_ui.is_empty():
		return
	drag_manager.start_drag(slot_ui, mouse_pos)

func _on_drag_started(_slot_index: int):
	_play_ui_sound("ui_drag_start")

func _on_drag_completed(from_slot: int, to_slot: int):
	if controller:
		var success = controller.move_item(from_slot, to_slot)
		_play_ui_sound("ui_drag_success" if success else "ui_drag_fail")

func _on_drag_cancelled():
	_play_ui_sound("ui_drag_cancel")

# === GESTION DES CLICS ===
func _on_slot_clicked(_slot_index: int, _slot_ui: InventorySlotUI):
	pass

func _on_slot_right_clicked(_slot_index: int, _slot_ui: InventorySlotUI):
	pass

func _on_slot_hovered(_slot_index: int, _slot_ui: InventorySlotUI):
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
