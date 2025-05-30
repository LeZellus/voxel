# scripts/inventory/ui/DragDropManager.gd - VERSION STYLE SIMPLE
class_name DragDropManager
extends Control

signal drag_started(slot_index: int)
signal drag_completed(from_slot: int, to_slot: int)
signal drag_cancelled()

var drag_preview: Control
var shake_tween: Tween
var is_dragging: bool = false
var drag_source_slot: int = -1
var drag_offset: Vector2
var original_slot_ui: InventorySlotUI
var inventory_grid: InventoryGridUI

func _ready():
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
	
	# Calculer l'offset AVANT de créer le preview
	drag_offset = slot_ui.size * 0.5
	
	# Créer l'aperçu de drag directement à la bonne position
	create_drag_preview(slot_ui, mouse_pos)
	
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
	# Arrêter l'animation de tremblement
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		shake_tween = null
	
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	
	if original_slot_ui:
		original_slot_ui.set_drag_preview_mode(false)
		original_slot_ui = null
	
	is_dragging = false
	drag_source_slot = -1

func create_drag_preview(slot_ui: InventorySlotUI, initial_mouse_pos: Vector2):
	"""Crée un aperçu simple identique au style des slots"""
	
	# Créer le conteneur principal
	drag_preview = Control.new()
	drag_preview.size = slot_ui.size
	drag_preview.z_index = 1000
	
	# Positionner immédiatement à la bonne position
	drag_preview.global_position = initial_mouse_pos - drag_offset
	
	# Background simple - même style que le slot mais couleur différente
	var background = ColorRect.new()
	background.size = slot_ui.size
	background.color = Color(0.4, 0.4, 0.6, 0.9)  # Couleur légèrement différente
	drag_preview.add_child(background)
	
	# Récupérer les données du slot
	var slot_data = slot_ui.get_slot_data()
	var icon_texture = slot_data.get("icon")
	
	# Icône - exactement comme dans InventorySlotUI
	if icon_texture:
		var item_icon = TextureRect.new()
		item_icon.texture = icon_texture
		item_icon.size = slot_ui.size * 0.4
		# Calcul manuel pour centrer : (taille_parent - taille_enfant) / 2
		var centered_pos = (slot_ui.size - item_icon.size) / 2
		item_icon.position = centered_pos
		item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		drag_preview.add_child(item_icon)

		# Animation shaky sur l'icône
		start_shake_animation(item_icon)
	
	# Label de quantité - exactement comme dans InventorySlotUI
	var quantity = slot_data.get("quantity", 1)
	if quantity > 1:
		var quantity_label = Label.new()
		quantity_label.text = str(quantity)
		
		# Positionnement en bas à droite comme dans le slot original
		quantity_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		quantity_label.offset_left = -35
		quantity_label.offset_top = -20
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
		drag_preview.add_child(quantity_label)
	
	# Transparence légère pour l'effet de drag
	drag_preview.modulate.a = 0.85
	
	# Ajouter au parent
	add_child(drag_preview)

func start_shake_animation(icon: TextureRect):
	"""Démarre une animation de tremblement subtile sur l'icône"""
	shake_tween = create_tween()
	shake_tween.set_loops()
	
	# Position originale centrée
	var original_pos = icon.position
	
	# Tremblement plus rapide et plus naturel
	var shake_intensity = 4.0
	var shake_speed = 0.04
	
	# Séquence de tremblement aléatoire
	for i in range(6):
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_tween.tween_property(icon, "position", original_pos + random_offset, shake_speed)
	
	# Retour à la position centrée
	shake_tween.tween_property(icon, "position", original_pos, shake_speed)

func find_slot_at_position(pos: Vector2) -> InventorySlotUI:
	"""Trouve le slot à la position donnée"""
	if not inventory_grid:
		return null
	
	for slot_ui in inventory_grid.slots:
		if not slot_ui or not is_instance_valid(slot_ui):
			continue
			
		var rect = Rect2(slot_ui.global_position, slot_ui.size)
		if rect.has_point(pos):
			return slot_ui
	
	return null

# === DEBUG ===
func get_drag_info() -> String:
	if not is_dragging:
		return "Pas de drag en cours"
	return "Drag en cours: slot %d" % drag_source_slot
