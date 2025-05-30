# scripts/inventory/manager/InventoryManager.gd
class_name InventoryManager
extends Node

signal inventory_opened()
signal inventory_closed()

@export var inventory_ui_scene: PackedScene = preload("res://scenes/ui/InventoryUI.tscn")

var inventory: Inventory
var controller: InventoryController
var inventory_ui: Control
var is_open: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_inventory()
	setup_input_actions()

func setup_inventory():
	# Créer l'inventaire principal
	inventory = Inventory.new(Constants.INVENTORY_SIZE, "Player Inventory")
	
	# Créer le controller
	controller = InventoryController.new(inventory)
	
	# Connecter les signaux
	controller.action_performed.connect(_on_action_performed)
	
	print("✅ InventoryManager initialisé")

func setup_input_actions():
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_TAB
		InputMap.action_add_event("toggle_inventory", key_event)

func _input(event):
	if Input.is_action_just_pressed("toggle_inventory"):
		toggle_inventory()

# === GESTION UI ===
func toggle_inventory():
	if is_open:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	if is_open:
		return
		
	create_ui_if_needed()
	if not inventory_ui:
		return
	
	is_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	inventory_ui.show()
	
	# Son d'ouverture
	if AudioManager:
		AudioManager.play_ui_sound("ui_pop_on_1")
	
	inventory_opened.emit()

func close_inventory():
	if not is_open or not inventory_ui:
		return
	
	is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inventory_ui.hide()
	
	# Son de fermeture
	if AudioManager:
		AudioManager.play_ui_sound("ui_pop_off_1")
	
	inventory_closed.emit()

func create_ui_if_needed():
	if inventory_ui:
		return
	
	if not inventory_ui_scene:
		push_error("inventory_ui_scene non défini")
		return
	
	inventory_ui = inventory_ui_scene.instantiate()
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(inventory_ui)
	
	# Initialiser l'UI avec les données
	if inventory_ui.has_method("setup_inventory"):
		inventory_ui.setup_inventory(inventory, controller)

# === API PUBLIQUE ===
func add_item(item: Item, quantity: int = 1) -> int:
	return controller.add_item_to_inventory(item, quantity)

func remove_item(item_id: String, quantity: int = 1) -> int:
	return controller.remove_item_from_inventory(item_id, quantity)

func has_item(item_id: String, quantity: int = 1) -> bool:
	return inventory.has_item(item_id, quantity)

func get_item_count(item_id: String) -> int:
	return inventory.get_item_count(item_id)

# === CALLBACKS ===
func _on_action_performed(action_type: String, result: bool):
	print("📦 Action inventaire: ", action_type, " -> ", result)
