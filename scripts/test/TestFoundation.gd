# TestFoundation.gd - Test du système d'inventaire complet
extends CanvasLayer

var test_grid_ui: InventoryGridUI  # Garder une référence

func _ready():
	print("🧪 === TEST SYSTÈME INVENTAIRE COMPLET ===")
	await get_tree().process_frame
	test_complete_system()
	test_ui_preparation()

func test_complete_system():
	print("\n📦 === TEST BACKEND INVENTAIRE ===")
	
	# Créer des items de test
	var apple = Item.new("apple", "Pomme")
	apple.max_stack_size = 10
	apple.is_stackable = true
	
	var sword = Item.new("sword", "Épée")
	sword.max_stack_size = 1
	sword.is_stackable = false
	
	var wood = Item.new("wood", "Bois")
	wood.max_stack_size = 50
	wood.is_stackable = true
	
	print("✅ Items créés:", apple.name, sword.name, wood.name)
	
	# Créer inventaire et controller
	var inventory = Inventory.new(9, "Test Inventory")
	var controller = InventoryController.new(inventory)
	
	print("✅ Inventaire créé: ", controller.get_inventory_summary())
	
	# Test ajout d'items
	print("\n➕ Test ajout d'items:")
	var surplus1 = controller.add_item_to_inventory(apple, 15)
	print("   Pommes ajoutées (surplus:", surplus1, ")")
	
	var surplus2 = controller.add_item_to_inventory(wood, 25)
	print("   Bois ajouté (surplus:", surplus2, ")")
	
	var surplus3 = controller.add_item_to_inventory(sword, 1)
	print("   Épée ajoutée (surplus:", surplus3, ")")
	
	inventory.print_contents()
	
	# Test move
	print("\n🔄 Test déplacement:")
	var moved = controller.move_item(0, 5)
	print("   Déplacement slot 0→5:", moved)
	inventory.print_contents()
	
	# Test undo
	print("\n⏪ Test undo:")
	var undone = controller.undo_last_action()
	print("   Undo:", undone)
	inventory.print_contents()

func test_ui_preparation():
	print("\n🎨 === TEST PRÉPARATION UI ===")
	
	# Créer texture de test pour les icônes
	var test_texture = _create_test_texture(Color.RED)
	var test_texture2 = _create_test_texture(Color.BLUE)
	var test_texture3 = _create_test_texture(Color.GREEN)
	
	print("✅ Textures de test créées")
	
	# Test de la grille UI
	test_inventory_grid_ui()

func _create_test_texture(color: Color) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func test_inventory_grid_ui():
	print("\n🔲 === TEST GRILLE UI ===")
	
	if ResourceLoader.exists("res://scenes/ui/InventoryGridUI.tscn"):
		var grid_ui_scene = preload("res://scenes/ui/InventoryGridUI.tscn")
		test_grid_ui = grid_ui_scene.instantiate()
		add_child(test_grid_ui)
		
		# Centrer la grille à l'écran
		var viewport_size = get_viewport().get_visible_rect().size
		test_grid_ui.position = Vector2(
			(viewport_size.x - 250) / 2,
			(viewport_size.y - 250) / 2
		)
		
		print("🔧 DEBUG: Viewport size:", viewport_size)
		print("🔧 DEBUG: Grid position:", test_grid_ui.position)
		
		# Attendre que la grille soit créée
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Tester avec des données de plusieurs slots
		var grid_test_data = [
			{
				"is_empty": false,
				"item_name": "Pomme",
				"quantity": 8,
				"icon": _create_test_texture(Color.RED)
			},
			{
				"is_empty": true
			},
			{
				"is_empty": false,
				"item_name": "Bois", 
				"quantity": 25,
				"icon": _create_test_texture(Color(0.6, 0.3, 0.1))
			},
			{
				"is_empty": false,
				"item_name": "Épée",
				"quantity": 1,
				"icon": _create_test_texture(Color.SILVER)
			}
		]
		
		# Mettre à jour la grille avec les données
		test_grid_ui.update_all_slots(grid_test_data)
		
		# Connecter aux signaux pour tester les interactions
		test_grid_ui.slot_clicked.connect(_on_grid_slot_clicked)
		test_grid_ui.slot_right_clicked.connect(_on_grid_slot_right_clicked)
		test_grid_ui.slot_hovered.connect(_on_grid_slot_hovered)
		
		print("✅ Grille UI créée et testée - VISIBLE à l'écran")
		print("🖱️ Clique sur les slots pour tester les interactions")
		print("🎯 La grille devrait être visible au centre de l'écran")
		
		# Afficher l'état de la grille
		test_grid_ui.print_grid_state()
		
		# Test de sélection
		test_grid_ui.set_slot_selected(0, true)
		print("✅ Slot 0 sélectionné pour test (devrait être jaune)")
		
		# Ajouter un bouton pour fermer si nécessaire
		_add_close_button()
		
	else:
		print("⚠️ InventoryGridUI.tscn pas trouvé")

func _add_close_button():
	var close_button = Button.new()
	close_button.text = "Fermer Test"
	close_button.position = Vector2(20, 20)
	close_button.size = Vector2(100, 30)
	close_button.pressed.connect(_close_test)
	add_child(close_button)

func _close_test():
	if test_grid_ui:
		test_grid_ui.queue_free()
	print("🔒 Test fermé")

func _on_grid_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	print("🎯 TEST: Slot", slot_index, "cliqué - Item:", slot_ui.get_item_name())

func _on_grid_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	print("🎯 TEST: Slot", slot_index, "clic droit - Item:", slot_ui.get_item_name())

func _on_grid_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	print("🎯 TEST: Slot", slot_index, "survolé - Item:", slot_ui.get_item_name())

# Input pour fermer avec Escape
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_close_test()
