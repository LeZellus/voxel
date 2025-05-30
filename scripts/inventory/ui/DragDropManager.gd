# scripts/inventory/ui/DragDropManager.gd
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

@onready var drag_layer = CanvasLayer.new()

func _ready():
	add_child(drag_layer)
	drag_layer.layer = 100  # Au-dessus de tout

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
	slot_ui.modulate.a = 0.5
	
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
	var target_slot = find_slot_at_position(mouse_pos)
	
	if target_slot != null and target_slot.get_slot_index() != drag_source_slot:
		# Drop valide
		drag_completed.emit(drag_source_slot, target_slot.get_slot_index())
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
		original_slot_ui.modulate.a = 1.0
		original_slot_ui = null
	
	is_dragging = false
	drag_source_slot = -1

func create_drag_preview(slot_ui: InventorySlotUI):
	drag_preview = Control.new()
	drag_preview.size = slot_ui.size
	
	# Copier l'apparence du slot
	var preview_bg = ColorRect.new()
	preview_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	preview_bg.size = slot_ui.size
	drag_preview.add_child(preview_bg)
	
	if slot_ui.item_icon.texture:
		var preview_icon = TextureRect.new()
		preview_icon.texture = slot_ui.item_icon.texture
		preview_icon.size = slot_ui.size * 0.8
		preview_icon.position = slot_ui.size * 0.1
		preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		drag_preview.add_child(preview_icon)
	
	# Ajouter un effet de transparence
	drag_preview.modulate.a = 0.8
	
	drag_layer.add_child(drag_preview)

func find_slot_at_position(pos: Vector2) -> InventorySlotUI:
	# Chercher récursivement tous les InventorySlotUI
	return _find_slot_recursive(get_tree().current_scene, pos)

func _find_slot_recursive(node: Node, pos: Vector2) -> InventorySlotUI:
	# Vérifier si c'est un InventorySlotUI
	if node is InventorySlotUI:
		var slot_ui = node as InventorySlotUI
		var rect = Rect2(slot_ui.global_position, slot_ui.size)
		if rect.has_point(pos):
			return slot_ui
	
	# Chercher dans les enfants
	for child in node.get_children():
		var result = _find_slot_recursive(child, pos)
		if result:
			return result
	
	return null
