# scripts/click_system/InventorySystem.gd
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
	"""Crée les containers par défaut"""
	
	# Inventaire principal - SANS UI pour l'instant
	var main_inventory = ClickableContainer.new(
		"player_inventory", 
		Constants.INVENTORY_SIZE, 
		"res://scenes/test/click_system/ui/NewInventoryUI.tscn"
	)
	
	add_child(main_inventory)
	main_inventory.container_ready.connect(_on_container_ready)
	
	# Hotbar - SANS UI pour l'instant
	var hotbar = ClickableContainer.new(
		"player_hotbar", 
		9, 
		"res://scenes/test/click_system/ui/TestHotbarUI.tscn"
	)
	add_child(hotbar)
	hotbar.container_ready.connect(_on_container_ready)

func _setup_input():
	"""Configure les raccourcis clavier"""
	
	# Vérifier/créer les actions
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_E
		InputMap.action_add_event("toggle_inventory", key_event)
	
	# Hotbar toujours visible (pas de toggle)
	var hotbar = get_container("player_hotbar")
	if hotbar:
		hotbar.show_ui()

func _input(event):
	"""Gestion des inputs globaux"""
	if event.is_action_pressed("toggle_inventory"):
		toggle_main_inventory()

# === GESTION CONTAINERS ===

func _on_container_ready(container_id: String, controller):
	"""Callback quand un container est prêt"""
	var container = _find_container_by_id(container_id)
	
	if container:
		containers[container_id] = container
		
		# Enregistrer dans le click system AVEC l'UI
		click_integrator.register_container(container_id, controller, container.ui)
		
		container_registered.emit(container_id)
		print("📦 Container enregistré: %s" % container_id)

func _find_container_by_id(container_id: String) -> ClickableContainer:
	"""Trouve un container par son ID"""
	for child in get_children():
		if child is ClickableContainer and child.get_container_id() == container_id:
			return child
	return null

# === API PUBLIQUE ===

func get_container(container_id: String) -> ClickableContainer:
	"""Récupère un container par son ID"""
	return containers.get(container_id)

func get_main_inventory() -> ClickableContainer:
	"""Raccourci pour l'inventaire principal"""
	return get_container("player_inventory")

func get_hotbar() -> ClickableContainer:
	"""Raccourci pour la hotbar"""
	return get_container("player_hotbar")

func toggle_main_inventory():
	"""Bascule l'affichage de l'inventaire principal"""
	var main_inv = get_main_inventory()
	if main_inv:
		main_inv.toggle_ui()

# === API ITEMS ===

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
	var main_count = get_main_inventory().get_item_count(item_id) if get_main_inventory() else 0
	var hotbar_count = get_hotbar().get_item_count(item_id) if get_hotbar() else 0
	
	return (main_count + hotbar_count) >= quantity

# === DEBUG ===

func debug_all_containers():
	"""Affiche les infos de tous les containers"""
	print("\n🎮 === DEBUG INVENTORY SYSTEM ===")
	for container_id in containers.keys():
		var container = containers[container_id]
		container.debug_info()
	
	if click_integrator and click_integrator.click_system:
		click_integrator.click_system.print_debug_info()
