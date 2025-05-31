# scripts/inventory/InventorySystem.gd - VERSION AVEC CONFIG CENTRALISÉE
class_name InventorySystem
extends Node

# === SIGNAUX ===
signal system_ready()
signal container_registered(container_id: String)

# === CONTAINERS ===
var containers: Dictionary = {}
var click_integrator: ClickSystemIntegrator

func _ready():
	print("🎮 InventorySystem démarré")
	
	# Valider la config avant tout
	InventoryConfig.validate_config()
	
	await _setup_click_system()
	await _create_containers()
	_setup_input()
	
	system_ready.emit()
	print("✅ InventorySystem prêt")

# === SETUP ===

func _setup_click_system():
	"""Crée et configure le système de clic"""
	click_integrator = ClickSystemIntegrator.new()
	add_child(click_integrator)
	
	await get_tree().process_frame
	print("✅ Click system configuré")

func _create_containers():
	"""Crée les containers à partir de la configuration"""
	
	# Créer l'inventaire principal
	_create_container_from_config("main")
	
	# Créer la hotbar
	_create_container_from_config("hotbar")

func _create_container_from_config(config_key: String):
	"""Crée un container à partir d'une clé de configuration"""
	var config = InventoryConfig.get_inventory_config(config_key)
	
	if config.is_empty():
		print("❌ Configuration introuvable pour: %s" % config_key)
		return
	
	var container = ClickableContainer.new(
		config.id,
		config.size,
		config.ui_scene
	)
	
	add_child(container)
	container.container_ready.connect(_on_container_ready)
	
	print("🔧 Container '%s' créé depuis config '%s'" % [config.id, config_key])

func _setup_input():
	"""Configure les raccourcis clavier"""
	
	# Vérifier/créer les actions
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_E
		InputMap.action_add_event("toggle_inventory", key_event)
	
	# Afficher les inventaires par défaut selon la config
	await get_tree().process_frame
	
	if InventoryConfig.is_visible_by_default("hotbar"):
		var hotbar = get_container(InventoryConfig.get_inventory_id("hotbar"))
		if hotbar:
			hotbar.show_ui()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		var main_inv = get_main_inventory()
		if main_inv:
			if main_inv.is_ui_visible:
				main_inv.hide_ui()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				main_inv.show_ui()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# === GESTION CONTAINERS ===

func _on_container_ready(container_id: String, controller):
	"""Callback quand un container est prêt"""
	var container = _find_container_by_id(container_id)
	
	if not container:
		print("❌ Container introuvable: %s" % container_id)
		return
	
	# Vérifier que l'inventaire existe
	var inventory = container.get_inventory()
	if not inventory:
		print("❌ Inventaire manquant pour %s" % container_id)
		return
	
	# NOUVEAU: Appliquer le nom d'affichage depuis la config
	_apply_display_name_from_config(inventory, container_id)
	
	containers[container_id] = container
	
	# Enregistrer dans le click system AVEC l'UI
	click_integrator.register_container(container_id, controller, container.ui)
	
	container_registered.emit(container_id)
	print("📦 Container enregistré: %s (nom: '%s')" % [container_id, inventory.name])

func _apply_display_name_from_config(inventory, container_id: String):
	"""Applique le nom d'affichage depuis la configuration"""
	
	# Chercher la config correspondante
	for config_key in InventoryConfig.INVENTORIES.keys():
		var config = InventoryConfig.get_inventory_config(config_key)
		if config.id == container_id:
			inventory.name = config.display_name
			print("📝 Nom appliqué: '%s' -> '%s'" % [container_id, config.display_name])
			
			# NOUVEAU: Mettre à jour l'UI du container aussi
			var container = _find_container_by_id(container_id)
			if container and container.has_method("update_inventory_name"):
				container.update_inventory_name(config.display_name)
			
			return
	
	print("⚠️ Aucune config trouvée pour le container: %s" % container_id)

func _find_container_by_id(container_id: String) -> ClickableContainer:
	"""Trouve un container par son ID"""
	for child in get_children():
		if child is ClickableContainer and child.get_container_id() == container_id:
			return child
	return null

# === API PUBLIQUE (adaptée à la nouvelle config) ===

func get_container(container_id: String) -> ClickableContainer:
	"""Récupère un container par son ID"""
	return containers.get(container_id)

func get_main_inventory() -> ClickableContainer:
	"""Raccourci pour l'inventaire principal"""
	return get_container(InventoryConfig.get_inventory_id("main"))

func get_hotbar() -> ClickableContainer:
	"""Raccourci pour la hotbar"""
	return get_container(InventoryConfig.get_inventory_id("hotbar"))

func get_click_integrator() -> ClickSystemIntegrator:
	"""Accès public au click integrator"""
	return click_integrator

func toggle_main_inventory():
	"""Bascule l'affichage de l'inventaire principal"""
	var main_inv = get_main_inventory()
	if main_inv:
		main_inv.toggle_ui()
		print("📦 Toggle inventaire")

# === API ITEMS (inchangée) ===

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	"""Ajoute un item à l'inventaire principal"""
	var main_inv = get_main_inventory()
	if main_inv:
		return main_inv.add_item(item, quantity)
	return quantity

func add_item_to_hotbar(item: Item, quantity: int = 1) -> int:
	"""Ajoute un item à la hotbar"""
	var hotbar = get_hotbar()
	if hotbar:
		return hotbar.add_item(item, quantity)
	return quantity

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Vérifie si le joueur a un item (inventaire + hotbar)"""
	var main_count = 0
	var hotbar_count = 0
	
	var main_inv = get_main_inventory()
	if main_inv:
		main_count = main_inv.get_item_count(item_id)
	
	var hotbar = get_hotbar()
	if hotbar:
		hotbar_count = hotbar.get_item_count(item_id)
	
	return (main_count + hotbar_count) >= quantity

# === DEBUG ===

func debug_all_containers():
	"""Affiche les infos de tous les containers"""
	print("\n🎮 === DEBUG INVENTORY SYSTEM ===")
	print("Containers enregistrés: %d" % containers.size())
	
	# Afficher la config d'abord
	InventoryConfig.print_all_configs()
	
	for container_id in containers.keys():
		var container = containers[container_id]
		if container:
			container.debug_info()
			
			# Vérifier l'inventaire
			var inventory = container.get_inventory()
			if inventory:
				print("   - Inventaire: %s (%d/%d slots)" % [inventory.name, inventory.get_used_slots_count(), inventory.size])
			else:
				print("   - ❌ Inventaire manquant!")
	
	if click_integrator and click_integrator.click_system:
		click_integrator.click_system.print_debug_info()
