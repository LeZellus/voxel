# scripts/manager/InventoryManager.gd - FICHIER MANQUANT CRÉÉ
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
	print("✅ InventoryManager initialisé")

func setup_inventory():
	# Créer l'inventaire principal avec vérification de Constants
	var size = 36  # Fallback si Constants n'existe pas
	if GameConfig and GameConfig.get_player_config():
		# Utiliser GameConfig si disponible
		pass
	
	inventory = Inventory.new(size, "Player Inventory")
	controller = InventoryController.new(inventory)
	
	# Connecter les signaux avec vérification
	if controller.has_signal("action_performed"):
		controller.action_performed.connect(_on_action_performed)

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
		print("❌ Impossible de créer l'UI d'inventaire")
		return
	
	is_open = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Animation d'ouverture si disponible
	if inventory_ui.has_method("show_animated"):
		inventory_ui.show_animated()
	else:
		inventory_ui.show()
	
	# Son d'ouverture avec vérification
	_play_ui_sound("ui_pop_on_1")
	inventory_opened.emit()

func close_inventory():
	if not is_open or not inventory_ui:
		return
	
	is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Animation de fermeture si disponible
	if inventory_ui.has_method("hide_animated"):
		inventory_ui.hide_animated()
	else:
		inventory_ui.hide()
	
	# Son de fermeture avec vérification
	_play_ui_sound("ui_pop_off_1")
	inventory_closed.emit()

func create_ui_if_needed():
	if inventory_ui:
		return
	
	if not inventory_ui_scene:
		push_error("inventory_ui_scene non défini dans InventoryManager")
		return
	
	inventory_ui = inventory_ui_scene.instantiate()
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_ui.visible = false
	
	# Ajouter à la scène
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(inventory_ui)
	else:
		# Fallback : ajouter au root
		get_tree().root.add_child(inventory_ui)
	
	# Attendre que l'UI soit prête
	await get_tree().process_frame
	
	# Initialiser l'UI avec les données
	if inventory_ui.has_method("setup_inventory"):
		inventory_ui.setup_inventory(inventory, controller)
	else:
		print("⚠️ L'UI d'inventaire n'a pas de méthode setup_inventory")

# === API PUBLIQUE ===
func add_item(item: Item, quantity: int = 1) -> int:
	if not controller:
		print("❌ Controller non initialisé")
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

func get_inventory() -> Inventory:
	return inventory

func get_controller() -> InventoryController:
	return controller

# === UTILITAIRES PRIVÉES ===
func _play_ui_sound(sound_name: String):
	# Vérification sécurisée de AudioManager
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("play_ui_sound"):
		audio_manager.play_ui_sound(sound_name)

func _on_action_performed(action_type: String, result: bool):
	print("📦 Action inventaire: ", action_type, " -> ", result)
