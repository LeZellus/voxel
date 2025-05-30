# TestFoundation.gd - Test du système d'inventaire complet
extends Node

func _ready():
	print("🧪 === TEST SYSTÈME INVENTAIRE COMPLET ===")
	await get_tree().process_frame  # Attendre 1 frame
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
	var inventory = Inventory.new(9, "Test Inventory")  # 3x3 pour test
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
	
	# Test redo
	print("\n⏩ Test redo:")
	var redone = controller.redo_last_action()
	print("   Redo:", redone)
	inventory.print_contents()
	
	# Test queries
	print("\n🔍 Test informations slots:")
	for i in range(3):
		var slot_info = controller.get_slot_info(i)
		if not slot_info.get("is_empty", true):
			print("   Slot", i, ":", slot_info.get("item_name"), "x", slot_info.get("quantity"))
		else:
			print("   Slot", i, ": vide")
	
	print("\n📊 Résumé final:", controller.get_inventory_summary())

func test_ui_preparation():
	print("\n🎨 === TEST PRÉPARATION UI ===")
	
	# Créer texture de test pour les icônes
	var test_texture = _create_test_texture(Color.RED)
	var test_texture2 = _create_test_texture(Color.BLUE)
	var test_texture3 = _create_test_texture(Color.GREEN)
	
	print("✅ Textures de test créées")
	
	# Simuler des données de slots pour l'UI
	var test_slots_data = [
		{
			"index": 0,
			"is_empty": false,
			"item_name": "Pomme",
			"quantity": 8,
			"icon": test_texture,
			"max_stack": 10
		},
		{
			"index": 1,
			"is_empty": false,
			"item_name": "Bois",
			"quantity": 25,
			"icon": test_texture2,
			"max_stack": 50
		},
		{
			"index": 2,
			"is_empty": false,
			"item_name": "Épée",
			"quantity": 1,
			"icon": test_texture3,
			"max_stack": 1
		},
		{
			"index": 3,
			"is_empty": true
		}
	]
	
	print("✅ Données de slots simulées:")
	for slot_data in test_slots_data:
		if slot_data.get("is_empty", true):
			print("   Slot", slot_data.get("index"), ": vide")
		else:
			print("   Slot", slot_data.get("index"), ":", slot_data.get("item_name"), "x", slot_data.get("quantity"))
	
	# Test du slot UI si disponible
	test_inventory_slot_ui()

func _create_test_texture(color: Color) -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func test_inventory_slot_ui():
	print("\n🎛️ === TEST SLOT UI ===")
	
	# Test de création d'un slot UI (quand on aura la scène)
	var slot_ui_scene = preload("res://scenes/ui/InventorySlotUI.tscn")
	if slot_ui_scene:
		var slot_ui = slot_ui_scene.instantiate()
		add_child(slot_ui)
		
		# Test avec données
		var test_data = {
			"is_empty": false,
			"item_name": "Pomme",
			"quantity": 5,
			"icon": _create_test_texture(Color.RED)
		}
		
		slot_ui.update_slot(test_data)
		print("✅ Slot UI testé avec succès")
		
		# Nettoyer
		slot_ui.queue_free()
	else:
		print("⚠️ InventorySlotUI.tscn pas encore créé")
