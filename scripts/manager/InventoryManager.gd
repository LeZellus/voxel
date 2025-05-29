# InventoryManager.gd - Gestionnaire principal à attacher au joueur
extends Node

@export var inventory_ui_scene: PackedScene = preload("res://scenes/ui/InventoryUI.tscn")

var inventory: Inventory
var inventory_ui: Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crée l'inventaire
	inventory = Inventory.new()
	add_child(inventory)
	
	# Attendre que l'inventory soit prêt
	await get_tree().process_frame
	
	# Crée l'interface
	create_inventory_ui()
	
	# Configure les actions d'input
	setup_input_actions()
	
func create_inventory_ui():
	
	if not inventory_ui_scene:
		print("Erreur: inventory_ui_scene non défini")
		return
	
	# Instancie la scène
	inventory_ui = inventory_ui_scene.instantiate()
	inventory_ui.visible = false
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ajoute à la scène
	get_tree().current_scene.add_child(inventory_ui)
	
	# Attendre que l'UI soit prête
	await get_tree().process_frame
	
	# Initialise l'UI avec l'inventory
	if inventory and inventory_ui and inventory_ui.has_method("setup_inventory"):
		inventory_ui.setup_inventory(inventory, self)
	else:
		print("Erreur: Impossible d'initialiser l'UI")
		print("inventory: ", inventory)
		print("inventory_ui: ", inventory_ui)

func setup_input_actions():
	if InputMap.has_action("toggle_inventory"):
		InputMap.erase_action("toggle_inventory")
	
	InputMap.add_action("toggle_inventory")
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_TAB
	InputMap.action_add_event("toggle_inventory", key_event)

func _input(_event):
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_ui != null:
			toggle_inventory()
		else:
			print("Erreur: inventory_ui est null!")

func toggle_inventory():
	if not inventory_ui:
		return
	
	if inventory_ui.visible:
		# Fermer
		AudioManager.play_ui_sound("ui_pop_off_1")
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		inventory_ui.hide_animated()
	else:
		# Ouvrir
		AudioManager.play_ui_sound("ui_pop_on_1")
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		inventory_ui.show_animated()

# Méthodes publiques pour interagir avec l'inventaire
func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	if inventory:
		return inventory.add_item(item, quantity)
	return quantity

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	if inventory:
		return inventory.remove_item(item_id, quantity)
	return 0

func has_item_in_inventory(item_id: String, quantity: int = 1) -> bool:
	if inventory:
		return inventory.has_item(item_id, quantity)
	return false
