# TestFoundation.gd - Test du système d'inventaire avec InventoryManager
extends CanvasLayer

var inventory_manager: InventoryManager

func _ready():
	print("🧪 === TEST INVENTORY MANAGER ===")
	await get_tree().process_frame
	test_inventory_manager()

func test_inventory_manager():
	print("\n📦 === TEST BACKEND AVEC MANAGER ===")
	
	# Créer le manager
	inventory_manager = InventoryManager.new()
	add_child(inventory_manager)
	
	# Attendre l'initialisation
	await get_tree().process_frame
	
	print("✅ InventoryManager créé")
	
	# Créer des items de test avec icônes
	var apple = create_test_item("apple", "Pomme", 10, Color.RED)
	var wood = create_test_item("wood", "Bois", 50, Color(0.6, 0.3, 0.1))
	var sword = create_test_item("sword", "Épée", 1, Color.SILVER)
	
	print("✅ Items de test créés")
	
	# Test d'ajout
	print("\n➕ Test ajout d'items:")
	var surplus1 = inventory_manager.add_item(apple, 7)
	print("   Pommes ajoutées (surplus: %d)" % surplus1)
	
	var surplus2 = inventory_manager.add_item(wood, 23)
	print("   Bois ajouté (surplus: %d)" % surplus2)
	
	var surplus3 = inventory_manager.add_item(sword, 1)
	print("   Épée ajoutée (surplus: %d)" % surplus3)
	
	# Vérification
	print("\n📊 État de l'inventaire:")
	print("   Pommes: %d" % inventory_manager.get_item_count("apple"))
	print("   Bois: %d" % inventory_manager.get_item_count("wood"))
	print("   Épées: %d" % inventory_manager.get_item_count("sword"))
	
	# Test des commandes
	test_commands()
	
	# Test UI
	await get_tree().process_frame
	test_ui()

func test_commands():
	print("\n🔄 Test des commandes:")
	var controller = inventory_manager.controller
	
	# Test move
	var moved = controller.move_item(0, 5)
	print("   Move slot 0→5: %s" % moved)
	
	# Test undo
	var undone = controller.undo_last_action()
	print("   Undo: %s" % undone)
	
	# Test redo
	var redone = controller.redo_last_action()
	print("   Redo: %s" % redone)

func test_ui():
	print("\n🎨 === TEST UI ===")
	
	# Test ouverture/fermeture
	print("Ouverture de l'UI...")
	inventory_manager.open_inventory()
	
	if inventory_manager.is_open:
		print("✅ UI ouverte avec succès")
		
		# Fermer après 3 secondes
		await get_tree().create_timer(3.0).timeout
		print("Fermeture de l'UI...")
		inventory_manager.close_inventory()
		
		if not inventory_manager.is_open:
			print("✅ UI fermée avec succès")
		else:
			print("❌ Erreur fermeture UI")
	else:
		print("❌ Erreur ouverture UI")

func create_test_item(id: String, name: String, stack_size: int, color: Color) -> Item:
	var item = Item.new(id, name)
	item.max_stack_size = stack_size
	item.is_stackable = stack_size > 1
	item.icon = create_test_texture(color)
	return item

func create_test_texture(color: Color) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Input pour tester manuellement
# Ajoutez cette méthode dans TestFoundation.gd

func _input(event):
	if not inventory_manager:
		return
		
	if event.is_action_pressed("ui_accept"):
		print("🔄 Toggle inventaire manuel")
		inventory_manager.toggle_inventory()
	
	if event.is_action_pressed("ui_select") and inventory_manager.is_open:
		# Ajouter un item random pour tester
		var random_items = ["apple", "wood", "sword"]
		var random_id = random_items[randi() % random_items.size()]
		var test_item = create_test_item(random_id, "Item Test", 5, Color.CYAN)
		inventory_manager.add_item(test_item, randi() % 3 + 1)
		print("➕ Item ajouté: %s" % random_id)
	
	if event.is_action_pressed("ui_cancel"):
		if inventory_manager.is_open:
			inventory_manager.close_inventory()
		else:
			print("🔒 Test fermé")
			get_tree().quit()
