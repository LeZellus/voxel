# scripts/inventory/containers/BaseContainer.gd - VERSION COMPLÈTE
class_name BaseContainer
extends Node

# === SIGNAUX COMMUNS ===
signal container_opened()
signal container_closed()
signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)

# === PROPRIÉTÉS CORE ===
var inventory: Inventory
var controller: InventoryController
var container_id: String
var container_name: String

# === UI MANAGEMENT ===
var ui: Control
var ui_scene: PackedScene
var is_open: bool = false

# === CONFIGURATION ===
var auto_setup_input: bool = false
var input_action: String = ""

func _init(id: String, size: int, name: String = "", ui_scene_path: String = ""):
	container_id = id
	container_name = name if not name.is_empty() else id
	
	# Créer l'inventaire et le contrôleur
	inventory = Inventory.new(size, container_name)
	controller = InventoryController.new(inventory)
	
	# Charger la scène UI si fournie
	if not ui_scene_path.is_empty():
		ui_scene = load(ui_scene_path)
	
	# Connecter les signaux
	call_deferred("_connect_signals")

func _connect_signals():
	if controller and controller.has_signal("action_performed"):
		controller.action_performed.connect(_on_action_performed)
	
	if inventory and inventory.has_signal("item_added"):
		inventory.item_added.connect(_on_item_added)
	if inventory and inventory.has_signal("item_removed"):
		inventory.item_removed.connect(_on_item_removed)

# === GESTION UI GÉNÉRIQUE ===
func setup_ui(parent_node: Node = null) -> bool:
	"""Configure l'UI du container"""
	if not ui_scene:
		print("⚠️ Pas de scène UI définie pour ", container_id)
		return false
	
	ui = ui_scene.instantiate()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.visible = false
	
	# Trouver ou créer un CanvasLayer pour l'UI
	var target_parent = _find_or_create_canvas_layer(parent_node)
	if target_parent:
		target_parent.add_child(ui)
	else:
		print("❌ Impossible de créer un parent pour l'UI")
		return false
	
	# Attendre que l'UI soit prête
	await get_tree().process_frame
	
	# Initialiser l'UI avec les données
	if ui and ui.has_method("setup_inventory"):
		ui.setup_inventory(inventory, controller)
		print("✅ UI configurée pour ", container_id)
	else:
		print("⚠️ L'UI n'a pas de méthode setup_inventory")
	
	return true

func show_ui():
	"""Affiche l'UI avec animation si disponible"""
	print("🔍 show_ui appelé pour ", container_id)
	
	if not ui:
		print("❌ Pas d'UI à afficher pour ", container_id)
		return
	
	is_open = true
	
	# FORCER l'affichage direct sans animation pour debug
	ui.visible = true
	ui.modulate = Color(1, 1, 1, 1)  # Forcer alpha à 1
	
	print("🔍 ui visible forcé ? ", ui.visible)
	print("🔍 ui modulate forcé : ", ui.modulate)
	
	_play_ui_sound("ui_pop_on_1")
	_on_container_opened()
	container_opened.emit()

func hide_ui():
	"""Masque l'UI avec animation si disponible"""
	if not ui:
		return
	
	is_open = false
	
	# FORCER le masquage direct
	ui.visible = false
	
	_play_ui_sound("ui_pop_off_1")
	_on_container_closed()
	container_closed.emit()

func toggle_ui():
	"""Bascule l'affichage de l'UI"""
	if is_open:
		hide_ui()
	else:
		show_ui()

# === GESTION INPUT (OPTIONNEL) ===
func setup_input_toggle(action_name: String):
	"""Configure un input pour toggler l'UI"""
	auto_setup_input = true
	input_action = action_name
	set_process_unhandled_input(true)
	
	# Créer l'action si elle n'existe pas
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_TAB  # Par défaut
		InputMap.action_add_event(action_name, key_event)

func _unhandled_input(event):
	if auto_setup_input and event.is_action_pressed(input_action):
		toggle_ui()

# === API INVENTAIRE SIMPLIFIÉ ===
func add_item(item: Item, quantity: int = 1) -> int:
	if not controller:
		return quantity
	return controller.add_item_to_inventory(item, quantity)

func remove_item(item_id: String, quantity: int = 1) -> int:
	if not controller:
		return 0
	return controller.remove_item_from_inventory(item_id, quantity)

func has_item(item_id: String, quantity: int = 1) -> bool:
	if not inventory:
		return false
	return inventory.has_item(item_id, quantity)

func get_item_count(item_id: String) -> int:
	if not inventory:
		return 0
	return inventory.get_item_count(item_id)

func move_item(from_slot: int, to_slot: int) -> bool:
	if not controller:
		return false
	return controller.move_item(from_slot, to_slot)

# === HOOKS POUR SPÉCIALISATION ===
func _on_container_opened():
	"""Override dans les classes filles si nécessaire"""
	pass

func _on_container_closed():
	"""Override dans les classes filles si nécessaire"""
	pass

func _on_action_performed(action_type: String, result: bool):
	"""Gestion des actions d'inventaire"""
	# Override si besoin de logique spécifique
	pass

func _on_item_added(item: Item, quantity: int, slot_index: int):
	item_added.emit(item, quantity)

func _on_item_removed(item: Item, quantity: int, slot_index: int):
	item_removed.emit(item, quantity)

# === UTILITAIRES ===
func _play_ui_sound(sound_name: String):
	"""Son UI avec vérification sécurisée"""
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

func get_stats() -> Dictionary:
	"""Retourne les statistiques du container"""
	return {
		"id": container_id,
		"name": container_name,
		"size": inventory.get_size() if inventory else 0,
		"used_slots": inventory.get_used_slots_count() if inventory else 0,
		"free_slots": inventory.get_free_slots_count() if inventory else 0,
		"is_open": is_open
	}

func _find_or_create_canvas_layer(parent_node: Node = null) -> Node:
	"""Trouve un CanvasLayer existant ou en crée un"""
	
	# 1. Utiliser le parent fourni s'il existe
	if parent_node:
		return parent_node
	
	# 2. Chercher un CanvasLayer existant dans la scène
	var current_scene = get_tree().current_scene
	var existing_canvas = _find_canvas_layer_in_scene(current_scene)
	if existing_canvas:
		return existing_canvas
	
	# 3. Créer un nouveau CanvasLayer
	return _create_ui_canvas_layer()

func _find_canvas_layer_in_scene(node: Node) -> CanvasLayer:
	"""Cherche récursivement un CanvasLayer dans la scène"""
	if node is CanvasLayer:
		return node
	
	for child in node.get_children():
		var found = _find_canvas_layer_in_scene(child)
		if found:
			return found
	
	return null

func _create_ui_canvas_layer() -> CanvasLayer:
	"""Crée un CanvasLayer dédié pour les UI d'inventaire"""
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "InventoryUILayer"
	ui_layer.layer = 10  # Au-dessus du jeu
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# L'ajouter à la scène principale
	var current_scene = get_tree().current_scene
	current_scene.add_child(ui_layer)
	
	print("✅ CanvasLayer UI créé automatiquement")
	return ui_layer

# === GETTERS POUR COMPATIBILITÉ ===
func get_inventory() -> Inventory:
	"""Retourne l'inventaire (compatibilité avec ancien code)"""
	return inventory

func get_controller() -> InventoryController:
	"""Retourne le contrôleur (compatibilité avec ancien code)"""
	return controller

# === DEBUG ===
func print_contents():
	if inventory:
		inventory.print_contents()
	else:
		print("❌ Pas d'inventaire à afficher")
