# scripts/systems/inventory/InventorySystem.gd - GESTION SOURIS CORRIGÉE
class_name InventorySystem
extends Node

signal system_ready()

var containers: Dictionary = {}
var click_integrator: ClickSystemIntegrator

func _ready():
	print("🎮 InventorySystem avec gestion souris corrigée")
	await _setup_system()
	system_ready.emit()
	print("✅ InventorySystem prêt")

func _setup_system():
	click_integrator = ClickSystemIntegrator.new()
	add_child(click_integrator)
	
	await get_tree().process_frame
	_create_default_containers()
	_setup_input()

func _create_default_containers():
	_create_container_from_config("main")
	_create_container_from_config("hotbar")

func _create_container_from_config(config_key: String):
	var config = InventoryConfig.get_inventory_config(config_key)
	
	if config.is_empty():
		print("❌ Config introuvable: %s" % config_key)
		return
	
	var container = ClickableContainer.new(config.id, config.size, config.ui_scene)
	add_child(container)
	container.container_ready.connect(_on_container_ready)

func _on_container_ready(container_id: String, controller):
	var container = _find_container_by_id(container_id)
	if not container:
		return
	
	var config_key = _get_config_key_for_container_id(container_id)
	InventoryConfigHelper.apply_config_to_container(container, config_key)
	
	containers[container_id] = container
	click_integrator.register_container(container_id, controller, container.ui)

func _get_config_key_for_container_id(container_id: String) -> String:
	for config_key in InventoryConfig.INVENTORIES.keys():
		var config = InventoryConfig.get_inventory_config(config_key)
		if config.id == container_id:
			return config_key
	return ""

func _find_container_by_id(container_id: String) -> ClickableContainer:
	for child in get_children():
		if child is ClickableContainer and child.get_container_id() == container_id:
			return child
	return null

func _setup_input():
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_E
		InputMap.action_add_event("toggle_inventory", key_event)

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle_main_inventory()

# === API PUBLIQUE ===
func get_container(container_id: String) -> ClickableContainer:
	return containers.get(container_id)

func get_main_inventory() -> ClickableContainer:
	return get_container(InventoryConfig.get_inventory_id("main"))

func get_hotbar() -> ClickableContainer:
	return get_container(InventoryConfig.get_inventory_id("hotbar"))

func toggle_main_inventory():
	var main_inv = get_main_inventory()
	if main_inv:
		main_inv.toggle_ui()
		
		# CORRECTION CRUCIALE : Gestion souris appropriée
		_update_mouse_mode(main_inv.is_ui_visible)

func _update_mouse_mode(inventory_is_open: bool):
	"""Met à jour le mode souris selon l'état de l'inventaire"""
	if inventory_is_open:
		# Inventaire ouvert : souris visible pour les interactions UI
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("🖱️ Souris visible - inventaire ouvert")
	else:
		# Inventaire fermé : souris capturée pour le jeu
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("🖱️ Souris capturée - inventaire fermé")

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	var main_inv = get_main_inventory()
	return main_inv.add_item(item, quantity) if main_inv else quantity

func add_item_to_hotbar(item: Item, quantity: int = 1) -> int:
	var hotbar = get_hotbar()
	return hotbar.add_item(item, quantity) if hotbar else quantity

func has_item(item_id: String, quantity: int = 1) -> bool:
	var main_count = 0
	var hotbar_count = 0
	
	var main_inv = get_main_inventory()
	if main_inv:
		main_count = main_inv.get_item_count(item_id)
	
	var hotbar = get_hotbar()
	if hotbar:
		hotbar_count = hotbar.get_item_count(item_id)
	
	return (main_count + hotbar_count) >= quantity

func get_click_integrator() -> ClickSystemIntegrator:
	return click_integrator

# === DEBUG ===
func debug_all_containers():
	print("\n🎮 InventorySystem Debug:")
	print("   - Containers: %d" % containers.size())
	for container_id in containers.keys():
		var container = containers[container_id]
		print("   - %s: %s" % [container_id, "OK" if container else "ERROR"])
	
	if click_integrator:
		click_integrator.debug_system()
