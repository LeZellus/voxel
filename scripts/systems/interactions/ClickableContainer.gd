# scripts/inventory/click_system/containers/ClickableContainer.gd - AVEC MISE À JOUR DU NOM
class_name ClickableContainer
extends Node

# === SIGNAUX ===
signal container_ready(container_id: String, controller)

# === PROPRIÉTÉS ===
var container_id: String
var inventory # Pas de typage strict pour éviter les erreurs de référence
var controller # Pas de typage strict
var ui_scene_path: String

# === UI ===
var ui: Control
var is_ui_visible: bool = false

func _init(id: String, size: int, ui_path: String = ""):
	container_id = id
	ui_scene_path = ui_path
	
	# Créer l'inventaire et le contrôleur
	inventory = Inventory.new(size, id)
	controller = ClickableInventoryController.new(inventory)

func _ready():
	# Charger l'UI si spécifiée
	if not ui_scene_path.is_empty():
		await _load_ui()
	
	# Signaler que le container est prêt
	container_ready.emit(container_id, controller)

# === GESTION UI ===

func _load_ui():
	"""Charge et configure l'UI"""
	if ui_scene_path.is_empty():
		return
	
	var ui_scene = load(ui_scene_path)
	if not ui_scene:
		print("❌ Impossible de charger l'UI: %s" % ui_scene_path)
		return
	
	ui = ui_scene.instantiate()
	
	# Chercher un CanvasLayer ou créer
	var ui_parent = _find_or_create_ui_parent()
	ui_parent.add_child(ui)
	
	# Attendre que l'UI soit prête
	await get_tree().process_frame
	
	# Configurer l'UI avec nos données
	if ui.has_method("setup_with_clickable_container"):
		ui.setup_with_clickable_container(self)
	elif ui.has_method("setup_inventory"):
		ui.setup_inventory(inventory, controller)
	
	# Cacher par défaut
	ui.visible = false
	is_ui_visible = false

func _find_or_create_ui_parent() -> Node:
	"""Trouve ou crée un parent pour l'UI"""
	
	# Chercher un CanvasLayer existant
	var current_scene = get_tree().current_scene
	var canvas_layer = _find_canvas_layer_recursive(current_scene)
	
	if canvas_layer:
		return canvas_layer
	
	# Créer un nouveau CanvasLayer
	var new_canvas = CanvasLayer.new()
	new_canvas.name = "InventoryUILayer"
	new_canvas.layer = 10
	current_scene.add_child(new_canvas)
	
	return new_canvas

func _find_canvas_layer_recursive(node: Node) -> CanvasLayer:
	"""Cherche récursivement un CanvasLayer"""
	if node is CanvasLayer:
		return node
	
	for child in node.get_children():
		var result = _find_canvas_layer_recursive(child)
		if result:
			return result
	
	return null
	
func show_ui():
	"""Affiche l'UI du container"""
	if not ui:
		print("❌ Pas d'UI à afficher pour '%s'" % container_id)
		return
	
	if is_ui_visible:
		return
	
	is_ui_visible = true
	
	ui.show_ui()

func hide_ui():
	"""Cache l'UI du container"""
	if not ui or not is_ui_visible:
		return
	
	is_ui_visible = false
	
	# Utiliser la méthode de la classe fille
	ui.hide_ui()

func toggle_ui():
	"""Bascule l'affichage de l'UI"""
	if is_ui_visible:
		hide_ui()
	else:
		show_ui()
		
func _apply_default_visibility():
	"""Applique la visibilité par défaut selon la config"""
	var should_be_visible = _get_visibility_from_config()
	
	if should_be_visible:
		# Utiliser la méthode show_ui() de la classe fille
		ui.show_ui()
		is_ui_visible = true
	else:
		# Utiliser la méthode hide_ui() de la classe fille  
		ui.hide_ui()
		is_ui_visible = false
		
func _get_visibility_from_config() -> bool:
	"""Récupère la visibilité par défaut depuis InventoryConfig"""
	# Chercher dans toutes les configs
	for config_key in InventoryConfig.INVENTORIES.keys():
		var config = InventoryConfig.get_inventory_config(config_key)
		if config.get("id") == container_id:
			return config.get("visible_by_default", false)
	
	print("⚠️ Config non trouvée pour container: %s" % container_id)
	return false

# === NOUVELLE MÉTHODE POUR METTRE À JOUR LE NOM ===

func update_inventory_name(new_name: String):
	"""Met à jour le nom de l'inventaire et l'UI"""
	if inventory:
		inventory.name = new_name
		
		# Mettre à jour l'UI si elle existe
		if ui and ui.has_method("update_inventory_name"):
			ui.update_inventory_name()
		elif ui and ui.has_method("_update_title"):
			ui._update_title()

# === API CONTAINER ===

func add_item(item, quantity: int = 1) -> int:
	"""Ajoute un item au container"""
	if inventory and inventory.has_method("add_item"):
		return inventory.add_item(item, quantity)
	return quantity

func remove_item(item_id: String, quantity: int = 1) -> int:
	"""Retire un item du container"""
	if inventory and inventory.has_method("remove_item"):
		return inventory.remove_item(item_id, quantity)
	return 0

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Vérifie si le container a un item"""
	if inventory and inventory.has_method("has_item"):
		return inventory.has_item(item_id, quantity)
	return false

func get_item_count(item_id: String) -> int:
	"""Compte les items d'un type"""
	if inventory and inventory.has_method("get_item_count"):
		return inventory.get_item_count(item_id)
	return 0

# === GETTERS ===

func get_container_id() -> String:
	return container_id

func get_controller():
	return controller

func get_inventory():
	return inventory
