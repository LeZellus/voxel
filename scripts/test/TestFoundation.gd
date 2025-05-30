# scripts/test/TestFoundation.gd - VERSION CORRIGÉE AVEC DEBUG
extends CanvasLayer

var inventory_manager: PlayerInventory

func _ready():
	print("🚀 Début du test d'inventaire")
	
	# S'assurer que l'action toggle_inventory existe
	setup_input_actions()
	
	await get_tree().process_frame
	test_inventory_manager()

func setup_input_actions():
	"""Crée l'action toggle_inventory si elle n'existe pas"""
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_TAB
		InputMap.action_add_event("toggle_inventory", key_event)
		print("✅ Action toggle_inventory créée (Tab)")

func test_inventory_manager():
	print("📦 Création du PlayerInventory...")
	
	# Créer le manager
	inventory_manager = PlayerInventory.new()
	add_child(inventory_manager)
	
	# Attendre l'initialisation complète
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Vérifier que tout est bien initialisé
	if not inventory_manager.inventory:
		print("❌ Inventory non initialisé!")
		return
	
	if not inventory_manager.controller:
		print("❌ Controller non initialisé!")
		return
	
	print("✅ PlayerInventory créé avec succès")
	
	# Créer et tester des items APRÈS l'initialisation
	await create_and_test_items()

func create_and_test_items():
	print("🎯 Création des items de test...")
	
	# Créer des items de test avec des icônes valides
	var apple = create_test_item("apple", "Pomme", 10, Color.RED)
	var wood = create_test_item("wood", "Bois", 50, Color(0.6, 0.3, 0.1))
	var sword = create_test_item("sword", "Épée", 1, Color.SILVER)
	
	print("🍎 Item Apple créé - Icon: %s" % str(apple.icon))
	print("🪵 Item Wood créé - Icon: %s" % str(wood.icon))
	print("⚔️ Item Sword créé - Icon: %s" % str(sword.icon))
	
	# Ajouter les items à l'inventaire
	print("\n➕ Ajout des items...")
	
	var surplus_apple = inventory_manager.add_item(apple, 5)
	print("   Pommes ajoutées: %d (surplus: %d)" % [5 - surplus_apple, surplus_apple])
	
	var surplus_wood = inventory_manager.add_item(wood, 20)
	print("   Bois ajouté: %d (surplus: %d)" % [20 - surplus_wood, surplus_wood])
	
	var surplus_sword = inventory_manager.add_item(sword, 1)
	print("   Épées ajoutées: %d (surplus: %d)" % [1 - surplus_sword, surplus_sword])
	
	# Vérification des items dans l'inventaire
	print("\n📊 État de l'inventaire:")
	print("   Pommes: %d" % inventory_manager.get_item_count("apple"))
	print("   Bois: %d" % inventory_manager.get_item_count("wood"))
	print("   Épées: %d" % inventory_manager.get_item_count("sword"))
	
	# Test des données des slots
	print("\n🔍 Vérification des slots:")
	for i in range(5):  # Vérifier les 5 premiers slots
		var slot_info = inventory_manager.controller.get_slot_info(i)
		if not slot_info.get("is_empty", true):
			print("   Slot %d: %s x%d (icon: %s)" % [
				i,
				slot_info.get("item_name", "Unknown"),
				slot_info.get("quantity", 0),
				str(slot_info.get("icon"))
			])
		else:
			print("   Slot %d: vide" % i)
	
	print("\n🎮 Utilisez Tab pour ouvrir l'inventaire")
	print("🔒 Utilisez Escape pour fermer ou quitter")

func create_test_item(id: String, item_name: String, stack_size: int, color: Color) -> Item:
	"""Crée un item de test avec icône colorée VALIDE"""
	var item = Item.new(id, item_name)
	item.max_stack_size = stack_size
	item.is_stackable = stack_size > 1
	item.description = "Item de test: " + item_name
	
	# Créer une icône VALIDE
	var icon_texture = create_test_texture(color)
	item.icon = icon_texture
	
	# DEBUG: Vérifier que l'icône est bien créée
	print("🖼️ Icône créée pour %s: %s (valid: %s)" % [
		item_name, 
		str(icon_texture), 
		str(icon_texture != null and icon_texture is Texture2D)
	])
	
	return item

func create_test_texture(color: Color) -> ImageTexture:
	"""Crée une texture colorée simple et VALIDE pour les tests"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Vérifier que la texture est valide
	if not texture or not texture is Texture2D:
		print("❌ Erreur: Texture invalide créée!")
		return null
	
	return texture

# === CONTRÔLES MANUELS ===
func _input(event):
	if not inventory_manager:
		return
	
	# Toggle inventaire avec Tab
	if event.is_action_pressed("toggle_inventory"):
		inventory_manager.toggle_ui()
		print("🔄 Toggle inventaire")
	
	# Ajouter des items avec Espace
	elif event.is_action_pressed("ui_accept"):
		add_random_test_item()
	
	# Fermer test avec Escape
	elif event.is_action_pressed("ui_cancel"):
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
