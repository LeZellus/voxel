# scripts/click_system/test/TestInventoryData.gd
extends Node
class_name TestInventoryData

var inventory: Inventory
var controller: ClickableInventoryController

func _ready():
	print("🧪 TestInventoryData initialisé")
	setup_test_inventory()
	add_test_items()

func setup_test_inventory():
	"""Crée un inventaire simple pour les tests"""
	inventory = Inventory.new(Constants.INVENTORY_SIZE, "Test Inventory")
	controller = ClickableInventoryController.new(inventory)
	
	print("✅ Inventaire de test créé (%d slots)" % Constants.INVENTORY_SIZE)

func add_test_items():
	"""Ajoute quelques items de test"""
	await get_tree().process_frame
	
	# Créer des items de test simples
	var test_items = []
	
	for i in range(3):
		var item = Item.new()
		item.id = "test_item_%d" % i
		item.name = "Item Test %d" % (i + 1)
		item.max_stack_size = 10
		item.is_stackable = true
		item.item_type = Item.ItemType.CONSUMABLE
		
		# Créer une icône simple pour les tests
		item.icon = _create_test_icon(i)
		test_items.append(item)
	
	# Ajouter les items à l'inventaire
	inventory.add_item(test_items[0], 5)  # 5x Item Test 1
	inventory.add_item(test_items[1], 3)  # 3x Item Test 2
	inventory.add_item(test_items[2], 1)  # 1x Item Test 3
	
	print("✅ Items de test ajoutés")

func _create_test_icon(index: int) -> ImageTexture:
	"""Crée une icône colorée pour les tests"""
	var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA]
	var color = colors[index % colors.size()]
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func get_container_id() -> String:
	return "test_inventory"
