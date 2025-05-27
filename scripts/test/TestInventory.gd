# TestInventory.gd - Script temporaire pour tester l'inventaire
# À attacher à n'importe quel nœud dans votre scène principale
extends Node

func _ready():
	# Attend un peu que tout soit initialisé
	await get_tree().create_timer(1.0).timeout
	
	# Trouve le joueur et son inventaire
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Joueur non trouvé! Assurez-vous d'ajouter votre Player au groupe 'player'")
		return
	
	print("Joueur trouvé: ", player.name)
	print("Enfants du joueur: ")
	for child in player.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	var inventory_manager = player.get_node_or_null("InventoryManager")
	if not inventory_manager:
		print("InventoryManager non trouvé avec get_node!")
		inventory_manager = player.find_child("InventoryManager", true, false)
		if not inventory_manager:
			print("InventoryManager non trouvé avec find_child non plus!")
			return
		else:
			print("InventoryManager trouvé avec find_child!")
	else:
		print("InventoryManager trouvé avec get_node!")
	
	# Teste les items
	test_items(inventory_manager)

func test_items(inventory_manager):
	print("Test des items...")
	
	# Crée des items de test avec la bonne signature
	var test_item_1 = Item.new()
	test_item_1.id = "test_seeds"
	test_item_1.name = "Graines"
	test_item_1.description = "Des graines pour planter"
	test_item_1.item_type = "seed"
	test_item_1.stack_size = 64
	test_item_1.is_stackable = true
	
	var test_item_2 = Item.new()
	test_item_2.id = "test_tool"
	test_item_2.name = "Arrosoir"
	test_item_2.description = "Pour arroser les plantes"
	test_item_2.item_type = "tool"
	test_item_2.stack_size = 1
	test_item_2.is_stackable = false
	
	var test_item_3 = Item.new()
	test_item_3.id = "test_crop"
	test_item_3.name = "Carotte"
	test_item_3.description = "Une carotte fraîche"
	test_item_3.item_type = "crop"
	test_item_3.stack_size = 32
	test_item_3.is_stackable = true
	
	print("Items de test créés")
	
	# Ajoute les items via l'inventory_manager
	if inventory_manager.has_method("add_item_to_inventory"):
		print("Ajout des graines...")
		var result1 = inventory_manager.add_item_to_inventory(test_item_1, 10)
		print("Graines ajoutées, reste: ", result1)
		
		print("Ajout de l'arrosoir...")
		var result2 = inventory_manager.add_item_to_inventory(test_item_2, 1)
		print("Arrosoir ajouté, reste: ", result2)
		
		print("Ajout des carottes...")
		var result3 = inventory_manager.add_item_to_inventory(test_item_3, 5)
		print("Carottes ajoutées, reste: ", result3)
	else:
		print("Erreur: Méthode add_item_to_inventory non trouvée!")
		
		# Essai de méthode alternative - accès direct à l'inventory
		if inventory_manager.has_method("get") and inventory_manager.inventory:
			print("Ajout direct via inventory...")
			inventory_manager.inventory.add_item(test_item_1, 10)
			inventory_manager.inventory.add_item(test_item_2, 1)
			inventory_manager.inventory.add_item(test_item_3, 5)
			print("Items ajoutés directement")
	
	print("Test terminé! Appuyez sur E pour ouvrir l'inventaire.")
	print("Vous devriez voir:")
	print("- 10 Graines")
	print("- 1 Arrosoir") 
	print("- 5 Carottes")
