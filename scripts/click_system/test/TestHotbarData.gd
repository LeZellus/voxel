# scripts/click_system/test/TestHotbarData.gd
extends Node
class_name TestHotbarData

var inventory: Inventory
var controller: InventoryController
var selected_slot: int = 0

func _ready():
	print("🧪 TestHotbarData initialisé")
	setup_test_hotbar()
	add_test_items()

func setup_test_hotbar():
	"""Crée une hotbar simple pour les tests"""
	inventory = Inventory.new(9, "Test Hotbar")  # 9 slots pour la hotbar
	controller = InventoryController.new(inventory)
	
	print("✅ Hotbar de test créée (9 slots)")

func add_test_items():
	"""Ajoute quelques items de test dans la hotbar"""
	await get_tree().process_frame
	
	# Créer des outils de test
	var sword = Item.new()
	sword.id = "test_sword"
	sword.name = "Épée Test"
	sword.max_stack_size = 1
	sword.is_stackable = false
	sword.item_type = Item.ItemType.TOOL
	sword.icon = _create_test_icon(Color.SILVER)
	
	var apple = Item.new()
	apple.id = "test_apple"
	apple.name = "Pomme Test"
	apple.max_stack_size = 64
	apple.is_stackable = true
	apple.item_type = Item.ItemType.CONSUMABLE
	apple.icon = _create_test_icon(Color.RED)
	
	# Ajouter à la hotbar
	inventory.add_item(sword, 1)  # Slot 0
	inventory.add_item(apple, 10) # Slot 1
	
	print("✅ Items de test ajoutés à la hotbar")

func _create_test_icon(color: Color) -> ImageTexture:
	"""Crée une icône colorée pour les tests"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func select_slot(slot_index: int):
	"""Sélectionne un slot de la hotbar"""
	if slot_index >= 0 and slot_index < 9:
		selected_slot = slot_index
		print("🎯 Slot %d sélectionné" % slot_index)

func get_selected_slot() -> int:
	return selected_slot

func get_container_id() -> String:
	return "test_hotbar"
