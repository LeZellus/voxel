# InventoryManager.gd - Gestionnaire principal à attacher au joueur
# À sauvegarder dans : res://scripts/InventoryManager.gd
extends Node

# Pour l'instant on utilise l'UI simple, plus tard on pourra utiliser la vraie scène
# @export var inventory_ui_scene: PackedScene = preload("res://scenes/ui/InventoryUI.tscn")

var inventory: Inventory
var inventory_ui: Control

func _ready():
	print("InventoryManager _ready() démarré")
	
	# IMPORTANT: Configure le nœud pour continuer à fonctionner en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crée l'inventaire
	inventory = Inventory.new()
	add_child(inventory)
	print("Inventory créé et ajouté")
	
	# Crée l'interface (version simple pour l'instant)
	create_inventory_ui()
	print("create_inventory_ui() appelé")
	
	# Configure les actions d'input
	setup_input_actions()
	
	print("InventoryManager initialisé")
	print("inventory_ui est: ", inventory_ui)

func create_inventory_ui():
	print("create_inventory_ui() démarré")
	
	# Crée l'UI avec la structure attendue par InventoryUI.gd
	inventory_ui = Control.new()
	inventory_ui.name = "InventoryUI"
	inventory_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_ui.visible = false
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Structure attendue : Panel/VBoxContainer/InventoryGrid
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(600, 400)
	panel.position = Vector2(-300, -200)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var grid = GridContainer.new()
	grid.name = "InventoryGrid"
	grid.columns = 9
	
	# Style du panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Titre de l'inventaire
	var title = Label.new()
	title.text = "INVENTAIRE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 18)
	
	# Assemble la hiérarchie
	inventory_ui.add_child(panel)
	panel.add_child(vbox)
	vbox.add_child(title)
	vbox.add_child(grid)
	
	# Charge et attache le script InventoryUI
	var script = load("res://scripts/ui/InventoryUI.gd")
	if script:
		inventory_ui.set_script(script)
		print("Script InventoryUI.gd attaché")
		
		# Initialise l'UI après avoir attaché le script
		await get_tree().process_frame
		inventory_ui.setup_inventory(inventory, self)
	else:
		print("Attention: Script InventoryUI.gd non trouvé")
	
	# Ajoute à la scène
	get_tree().current_scene.add_child(inventory_ui)
	print("UI ajoutée à la scène")

func setup_input_actions():
	# Supprime l'action si elle existe déjà pour la recréer
	if InputMap.has_action("toggle_inventory"):
		InputMap.erase_action("toggle_inventory")
	
	# Crée l'action
	InputMap.add_action("toggle_inventory")
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_E
	InputMap.action_add_event("toggle_inventory", key_event)
	
	print("Action toggle_inventory créée avec la touche E")

func _input(event):
	# Test direct de la touche E - seulement si l'inventaire est fermé
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		print("Touche E détectée dans InventoryManager!")
		# Vérification de sécurité
		if inventory_ui != null:
			# Ne gère l'input que si l'inventaire est fermé
			if not inventory_ui.visible:
				print("Inventaire fermé - on l'ouvre")
				toggle_inventory()
			else:
				print("Inventaire déjà ouvert - l'UI va gérer la fermeture")
		else:
			print("Erreur: inventory_ui est null!")

func toggle_inventory():
	# Double vérification de sécurité
	if not inventory_ui:
		print("Erreur: Impossible de basculer l'inventaire - inventory_ui est null")
		return
	
	var was_visible = inventory_ui.visible
	inventory_ui.visible = !inventory_ui.visible
	
	print("Inventaire était: ", "visible" if was_visible else "caché")
	print("Inventaire maintenant: ", "visible" if inventory_ui.visible else "caché")
	
	if inventory_ui.visible:
		# Le jeu continue, on libère juste la souris
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("Souris libérée")
	else:
		# On capture la souris pour le mouvement de caméra
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("Souris capturée")

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
