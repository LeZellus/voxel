# scripts/inventory/ui/DragDropManager.gd - VERSION SIMPLIFIÉE ET CORRIGÉE
class_name DragDropManager
extends Control

signal drag_started(slot_index: int)
signal drag_completed(from_slot: int, to_slot: int)
signal drag_cancelled()

var drag_preview: Control
var is_dragging: bool = false
var drag_source_slot: int = -1
var drag_offset: Vector2
var original_slot_ui: InventorySlotUI
var inventory_grid: InventoryGridUI  # Référence directe à la grille

func _ready():
	# Pas besoin de CanvasLayer complexe
	set_process_input(true)

func set_inventory_grid(grid: InventoryGridUI):
	"""Définir la grille d'inventaire pour le drag & drop"""
	inventory_grid = grid

func start_drag(slot_ui: InventorySlotUI, mouse_pos: Vector2) -> bool:
	if is_dragging or slot_ui.is_empty():
		return false
	
	is_dragging = true
	drag_source_slot = slot_ui.get_slot_index()
	original_slot_ui = slot_ui
	
	# Créer l'aperçu de drag
	create_drag_preview(slot_ui)
	
	# Calculer l'offset pour centrer sur la souris
	drag_offset = slot_ui.size * 0.5
	
	# Masquer temporairement l'item original
	slot_ui.set_drag_preview_mode(true)
	
	drag_started.emit(drag_source_slot)
	return true

func _input(event):
	if not is_dragging:
		return
	
	if event is InputEventMouseMotion:
		update_drag_position(event.position)
	
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			complete_drag_at_position(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_drag()

func update_drag_position(mouse_pos: Vector2):
	if drag_preview:
		drag_preview.global_position = mouse_pos - drag_offset

func complete_drag_at_position(mouse_pos: Vector2):
	var target_slot_ui = find_slot_at_position(mouse_pos)
	
	if target_slot_ui and target_slot_ui.get_slot_index() != drag_source_slot:
		# Drop valide
		drag_completed.emit(drag_source_slot, target_slot_ui.get_slot_index())
	else:
		# Drop invalide
		cancel_drag()
	
	end_drag()

func cancel_drag():
	drag_cancelled.emit()
	end_drag()

func end_drag():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	
	if original_slot_ui:
		original_slot_ui.set_drag_preview_mode(false)
		original_slot_ui = null
	
	is_dragging = false
	drag_source_slot = -1

func create_drag_preview(slot_ui: InventorySlotUI):
	drag_preview = Control.new()
	drag_preview.size = slot_ui.size
	drag_preview.z_index = 1000  # Au-dessus de tout
	
	# Background simple
	var preview_bg = ColorRect.new()
	preview_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	preview_bg.size = slot_ui.size
	drag_preview.add_child(preview_bg)
	
	# Icône de l'item
	var slot_data = slot_ui.get_slot_data()
	var icon_texture = slot_data.get("icon")
	if icon_texture:
		var preview_icon = TextureRect.new()
		preview_icon.texture = icon_texture
		preview_icon.size = slot_ui.size * 0.8
		preview_icon.position = slot_ui.size * 0.1
		preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		drag_preview.add_child(preview_icon)
	
	# Effet de transparence
	drag_preview.modulate.a = 0.8
	
	# Ajouter au parent direct
	add_child(drag_preview)

func find_slot_at_position(pos: Vector2) -> InventorySlotUI:
	"""Version optimisée - utilise la référence directe à la grille"""
	if not inventory_grid:
		return null
	
	# Parcourir seulement les slots de la grille connue
	for slot_ui in inventory_grid.slots:
		if not slot_ui:
			continue
			
		var rect = Rect2(slot_ui.global_position, slot_ui.size)
		if rect.has_point(pos):
			return slot_ui
	
	return null
