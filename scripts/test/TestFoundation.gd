# TestCompleteSystem.gd
extends Node

func _ready():
	print("🧪 === TEST SYSTÈME COMPLET ===")
	test_complete_system()

func test_complete_system():
	# Créer des items
	var apple = Item.new("apple", "Pomme")
	apple.max_stack_size = 10
	apple.is_stackable = true
	
	var sword = Item.new("sword", "Épée")
	sword.max_stack_size = 1
	
	# Créer inventaire et controller
	var inventory = Inventory.new(5, "Test Inventory")
	var controller = InventoryController.new(inventory)
	
	print("\n📊 État initial:")
	print(controller.get_inventory_summary())
	
	# Test ajout d'items
	print("\n➕ Test ajout d'items:")
	var surplus = controller.add_item_to_inventory(apple, 15)
	print("✅ Ajout 15 pommes, surplus:", surplus)
	inventory.print_contents()
	
	# Test move
	print("\n🔄 Test déplacement:")
	var moved = controller.move_item(0, 2)
	print("✅ Déplacement slot 0→2:", moved)
	inventory.print_contents()
	
	# Test undo
	print("\n⏪ Test undo:")
	var undone = controller.undo_last_action()
	print("✅ Undo:", undone)
	inventory.print_contents()
	
	# Test queries
	print("\n🔍 Test slot info:")
	var slot_info = controller.get_slot_info(0)
	print("✅ Slot 0:", slot_info)
