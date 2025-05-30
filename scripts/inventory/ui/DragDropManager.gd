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
var inventory_grids: Array = []
var source_grid: Control

func _ready():
	set_process_input(true)

func set_inventory_grid(grid):
	print("🔧 DragDropManager: Ajout d'une grille: %s" % str(grid))
	
	if not grid:
		print("❌ DragDropManager: Grille null!")
		return
		
	if not grid.has_method("get_slot"):
		print("❌ DragDropManager: Grille sans méthode get_slot!")
		return
		
	if not grid.get("slots"):
		print("❌ DragDropManager: Grille sans propriété slots!")
		return
	
	if not inventory_grids.has(grid):
		inventory_grids.append(grid)
		print("✅ DragDropManager: Grille ajoutée. Total: %d grilles" % inventory_grids.size())
		
		# DEBUG: Lister toutes les grilles
		for i in inventory_grids.size():
			var g = inventory_grids[i]
			print("   - Grille %d: %s (%d slots)" % [i, str(g), g.get("slots").size() if g.get("slots") else 0])

func start_drag(slot_ui: InventorySlotUI, mouse_pos: Vector2) -> bool:
	print("🎯 DragDropManager: Tentative de start_drag sur slot %d" % slot_ui.get_slot_index())
	
	if is_dragging:
		print("❌ DragDropManager: Drag déjà en cours!")
		return false
	
	if slot_ui.is_empty():
		print("❌ DragDropManager: Slot vide!")
		return false
	
	# NOUVEAU: Identifier la grille source
	source_grid = _find_grid_for_slot(slot_ui)
	if not source_grid:
		print("❌ DragDropManager: Impossible de trouver la grille source!")
		return false
	
	print("✅ DragDropManager: Drag démarré avec succès depuis grille: %s" % str(source_grid))
	
	is_dragging = true
	drag_source_slot = slot_ui.get_slot_index()
	original_slot_ui = slot_ui
	
	drag_offset = slot_ui.size * 0.5
	create_drag_preview(slot_ui, mouse_pos)
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
	var target_info = find_slot_at_position(mouse_pos)
	
	if target_info.is_empty():
		print("❌ Aucun slot trouvé pour le drop")
		cancel_drag()
		end_drag()
		return
	
	var target_slot_ui = target_info.slot
	var target_grid = target_info.grid
	
	if target_slot_ui.get_slot_index() == drag_source_slot and target_grid == source_grid:
		print("❌ Drop sur le même slot - annulation")
		cancel_drag()
		end_drag()
		return
	
	# NOUVEAU: Détecter si c'est un cross-container
	if target_grid != source_grid:
		print("🔄 Cross-container detecté: %s -> %s" % [str(source_grid), str(target_grid)])
		_handle_cross_container_transfer(target_slot_ui, target_grid)
	else:
		print("🔄 Même conteneur - transfer normal")
		drag_completed.emit(drag_source_slot, target_slot_ui.get_slot_index())
	
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

func find_slot_at_position(pos: Vector2) -> Dictionary:
	print("🎯 DragDropManager: Recherche slot à position %s" % pos)
	print("🎯 Grilles disponibles: %d" % inventory_grids.size())
	
	for i in inventory_grids.size():
		var grid = inventory_grids[i]
		print("🎯 Test grille %d: %s" % [i, str(grid)])
		
		if not grid or not is_instance_valid(grid):
			print("❌ Grille %d invalide" % i)
			continue
		
		var slots_array = grid.get("slots")
		if not slots_array:
			print("❌ Grille %d sans slots" % i)
			continue
		
		print("🎯 Grille %d: %d slots à tester" % [i, slots_array.size()])
		
		for j in slots_array.size():
			var slot_ui = slots_array[j]
			if not slot_ui or not is_instance_valid(slot_ui):
				continue
			
			var rect = Rect2(slot_ui.global_position, slot_ui.size)
			print("🎯 Slot %d-%d: rect %s (mouse: %s)" % [i, j, rect, pos])
			
			if rect.has_point(pos):
				print("✅ TROUVÉ! Slot %d dans grille %d" % [j, i])
				return {
					"slot": slot_ui,
					"grid": grid,
					"grid_index": i
				}
	
	print("❌ Aucun slot trouvé à cette position")
	return {}

# === DEBUG ===
func get_drag_info() -> String:
	if not is_dragging:
		return "Pas de drag en cours"
	return "Drag en cours: slot %d" % drag_source_slot
	
func _find_grid_for_slot(slot_ui: InventorySlotUI) -> Control:
	for grid in inventory_grids:
		if not grid or not is_instance_valid(grid):
			continue
		
		var slots_array = grid.get("slots")
		if not slots_array:
			continue
		
		if slots_array.has(slot_ui):
			return grid
	
	return null
	
func _handle_cross_container_transfer(target_slot_ui: InventorySlotUI, target_grid: Control):
	print("🚀 Début transfert cross-container")
	
	# Obtenir les contrôleurs des deux grilles
	var source_controller = _get_controller_for_grid(source_grid)
	var target_controller = _get_controller_for_grid(target_grid)
	
	if not source_controller or not target_controller:
		print("❌ Impossible d'obtenir les contrôleurs")
		cancel_drag()
		return
	
	# Obtenir les informations du slot source
	var source_slot_info = source_controller.get_slot_info(drag_source_slot)
	if source_slot_info.is_empty:
		print("❌ Slot source vide!")
		cancel_drag()
		return
	
	# Tenter le transfert
	var success = _perform_cross_transfer(
		source_controller, drag_source_slot,
		target_controller, target_slot_ui.get_slot_index(),
		source_slot_info
	)
	
	if success:
		print("✅ Transfert cross-container réussi!")
		# Émettre un signal spécial pour le cross-container
		if has_signal("cross_container_transfer_completed"):
			pass # Sera ajouté si nécessaire
	else:
		print("❌ Échec du transfert cross-container")
		cancel_drag()
		
func _get_controller_for_grid(grid: Control) -> InventoryController:
	print("🔍 Recherche contrôleur pour grille: %s" % str(grid))
	
	# Méthode 1: Chercher dans l'arbre des parents
	var current = grid
	var depth = 0
	while current and depth < 10:  # Limite de sécurité
		print("🔍 Test node %d: %s (type: %s)" % [depth, str(current), current.get_class()])
		
		# Chercher un BaseContainer ou équivalent
		if current.has_method("get_controller"):
			var controller = current.get_controller()
			if controller:
				print("✅ Contrôleur trouvé via get_controller() sur: %s" % str(current))
				return controller
		
		# Chercher directement une propriété controller
		if current.has_method("get") and current.get("controller"):
			var controller = current.get("controller")
			if controller is InventoryController:
				print("✅ Contrôleur trouvé via propriété sur: %s" % str(current))
				return controller
		
		current = current.get_parent()
		depth += 1
	
	# Méthode 2: Chercher via PanelUI en utilisant l'arbre global
	var panel_ui = _find_panel_ui()
	if panel_ui:
		print("🔍 PanelUI trouvé: %s" % str(panel_ui))
		
		# Identifier quelle grille on cherche
		if grid.get_script() and "InventoryGrid" in str(grid.get_script().resource_path):
			print("🔍 C'est la grille inventaire principal")
			var inventory = panel_ui.get("inventory")
			if inventory and inventory.has_method("get_controller"):
				var controller = inventory.get_controller()
				if controller:
					print("✅ Contrôleur inventaire trouvé via PanelUI")
					return controller
		
		elif grid.get_script() and "HotbarUI" in str(grid.get_script().resource_path):
			print("🔍 C'est la grille hotbar")
			var hotbar = panel_ui.get("hotbar")
			if hotbar and hotbar.has_method("get_controller"):
				var controller = hotbar.get_controller()
				if controller:
					print("✅ Contrôleur hotbar trouvé via PanelUI")
					return controller
	
	print("❌ Contrôleur non trouvé pour la grille: %s" % str(grid))
	return null
	
func _perform_cross_transfer(
	source_ctrl: InventoryController, source_slot: int,
	target_ctrl: InventoryController, target_slot: int,
	source_info: Dictionary
) -> bool:
	
	print("🔄 Transfert: slot %d -> slot %d" % [source_slot, target_slot])
	print("🔄 Item: %s x%d" % [source_info.item_name, source_info.quantity])
	
	# Obtenir l'inventaire source pour récupérer l'objet Item réel
	var source_inventory = source_ctrl.inventory
	var source_slot_obj = source_inventory.get_slot(source_slot)
	
	if source_slot_obj.is_empty():
		print("❌ Slot source vide!")
		return false
	
	var item_obj = source_slot_obj.get_item()  # Objet Item réel
	var quantity = source_slot_obj.get_quantity()
	
	# Vérifier le slot cible
	var target_inventory = target_ctrl.inventory
	var target_slot_obj = target_inventory.get_slot(target_slot)
	
	print("🔄 Slot cible vide: %s" % str(target_slot_obj.is_empty()))
	
	# Cas 1: Slot cible vide - transfert simple
	if target_slot_obj.is_empty():
		print("🔄 Transfert vers slot vide")
		
		# Retirer de la source
		var removed_stack = source_slot_obj.remove_item(quantity)
		if removed_stack.quantity > 0:
			# Ajouter à la cible
			var surplus = target_slot_obj.add_item(item_obj, removed_stack.quantity)
			
			# Si surplus, remettre dans la source
			if surplus > 0:
				source_slot_obj.add_item(item_obj, surplus)
			
			print("✅ Transfert réussi: %d items transférés" % (removed_stack.quantity - surplus))
			return true
	
	# Cas 2: Même item stackable
	elif target_slot_obj.can_accept_item(item_obj, quantity):
		print("🔄 Stack avec items existants")
		
		var can_add = item_obj.max_stack_size - target_slot_obj.get_quantity()
		var to_transfer = min(quantity, can_add)
		
		if to_transfer > 0:
			var removed_stack = source_slot_obj.remove_item(to_transfer)
			if removed_stack.quantity > 0:
				target_slot_obj.add_item(item_obj, removed_stack.quantity)
				print("✅ Stack réussi: %d items transférés" % removed_stack.quantity)
				return true
	
	# Cas 3: Swap (échange de places)
	else:
		print("🔄 Échange de slots")
		
		var target_item = target_slot_obj.get_item()
		var target_quantity = target_slot_obj.get_quantity()
		
		# Vider les deux slots
		source_slot_obj.clear()
		target_slot_obj.clear()
		
		# Échanger
		target_slot_obj.add_item(item_obj, quantity)
		source_slot_obj.add_item(target_item, target_quantity)
		
		print("✅ Échange réussi")
		return true
	
	print("❌ Transfert impossible")
	return false
	
	print("🔄 Transfert: slot %d -> slot %d" % [source_slot, target_slot])
	print("🔄 Item: %s x%d" % [source_info.item_name, source_info.quantity])
	
	# Vérifier si le slot cible peut accepter l'item
	var target_info = target_ctrl.get_slot_info(target_slot)
	
	# Cas 1: Slot cible vide
	if target_info.is_empty:
		# Retirer de la source
		var removed = source_ctrl.remove_item_from_inventory(source_info.item_id, source_info.quantity)
		if removed > 0:
			# TODO: Obtenir l'objet Item pour l'ajouter à la cible
			# Pour l'instant, simuler la réussite
			print("✅ Transfer simulé réussi")
			return true
	
	# Cas 2: Même item stackable
	elif target_info.item_id == source_info.item_id:
		# Calculer combien on peut transférer
		var can_add = target_info.max_stack - target_info.quantity
		var to_transfer = min(source_info.quantity, can_add)
		
		if to_transfer > 0:
			var removed = source_ctrl.remove_item_from_inventory(source_info.item_id, to_transfer)
			if removed > 0:
				print("✅ Stack transfer simulé réussi")
				return true
	
	# Cas 3: Swap (pour plus tard)
	else:
		print("⚠️ Swap cross-container pas encore implémenté")
		return false
	
	return false
		
func _find_panel_ui() -> Node:
	# Chercher dans l'arbre de scène
	var root = get_tree().current_scene
	return _find_node_recursive(root, "PanelUI")

func _find_node_recursive(node: Node, name_pattern: String) -> Node:
	if node.name == name_pattern or name_pattern in node.name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, name_pattern)
		if result:
			return result
	
	return null
