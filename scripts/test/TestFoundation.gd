# scripts/test/TestFoundation.gd - VERSION AVEC TOGGLE MANUEL
extends CanvasLayer

var inventory_manager: PlayerInventory

func _ready():
	await get_tree().process_frame
	test_inventory_manager()

func test_inventory_manager():
	# Créer le manager
	inventory_manager = PlayerInventory.new()
	add_child(inventory_manager)
	
	# Attendre l'initialisation complète
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Créer des items de test APRÈS l'initialisation
	await create_and_test_items()
	
func create_and_test_items():
	# Créer des items de test avec icônes
	var apple = create_test_item("apple", "Pomme", 10, Color.RED)
	var wood = create_test_item("wood", "Bois", 50, Color(0.6, 0.3, 0.1))
	var sword = create_test_item("sword", "Épée", 1, Color.SILVER)
	
	if inventory_manager and inventory_manager.controller:
		# Vérification
		print("\n📊 État de l'inventaire:")
		print("   Pommes: %d" % inventory_manager.get_item_count("apple"))
		print("   Bois: %d" % inventory_manager.get_item_count("wood"))
		print("   Épées: %d" % inventory_manager.get_item_count("sword"))
		
		# Test des commandes
		test_commands()
	else:
		print("❌ Erreur : inventory_manager non valide")

func test_commands():
	print("\n🔄 Test des commandes:")
	var controller = inventory_manager.controller
	
	if controller:
		# Test move
		var moved = controller.move_item(0, 5)
		print("   Move slot 0→5: %s" % moved)
		
		# Test undo si disponible
		if controller.has_method("undo_last_action"):
			var undone = controller.undo_last_action()
			print("   Undo: %s" % undone)
			
			# Test redo si disponible
			if controller.has_method("redo_last_action"):
				var redone = controller.redo_last_action()
				print("   Redo: %s" % redone)
	else:
		print("❌ Controller non disponible")

func create_test_item(id: String, item_name: String, stack_size: int, color: Color) -> Item:
	"""Crée un item de test avec icône colorée"""
	var item = Item.new(id, item_name)
	item.max_stack_size = stack_size
	item.is_stackable = stack_size > 1
	item.icon = create_test_texture(color)
	item.description = "Item de test: " + item_name
	return item

func create_test_texture(color: Color) -> ImageTexture:
	"""Crée une texture colorée simple pour les tests"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# === CONTRÔLES MANUELS ===
func _input(event):
	if not inventory_manager:
		return
	
	# Toggle inventaire avec Espace OU Tab
	if event.is_action_pressed("toggle_inventory"):
		inventory_manager.toggle_ui()
	
	# Fermer test avec Escape
	if event.is_action_pressed("ui_cancel"):
		if inventory_manager.is_open:
			inventory_manager.hide_ui()
		else:
			print("🔒 Test fermé")
			get_tree().quit()

func add_random_test_item():
	"""Ajoute un item aléatoire pour tester"""
	var random_items = [
		{"id": "apple", "name": "Pomme", "color": Color.RED},
		{"id": "wood", "name": "Bois", "color": Color(0.6, 0.3, 0.1)},
		{"id": "sword", "name": "Épée", "color": Color.SILVER},
		{"id": "stone", "name": "Pierre", "color": Color.GRAY}
	]
	
	var random_data = random_items[randi() % random_items.size()]
	var test_item = create_test_item(
		random_data.id, 
		random_data.name, 
		randi() % 10 + 1,  # Stack size aléatoire
		random_data.color
	)
	
	var quantity = randi() % 5 + 1
	inventory_manager.add_item(test_item, quantity)
	print("➕ Item ajouté: %s x%d" % [random_data.name, quantity])
