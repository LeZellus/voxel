# scripts/inventory/containers/BaseContainer.gd
class_name BaseContainer
extends RefCounted

# Classe de base pour tous les conteneurs (inventaire, hotbar, coffre, etc.)

var inventory: Inventory
var controller: InventoryController
var ui: Control
var container_id: String
var container_system: ContainerSystem

func _init(id: String, size: int, name: String = ""):
	container_id = id
	inventory = Inventory.new(size, name.is_empty() and id or name)
	controller = InventoryController.new(inventory)

func show_ui():
	if ui:
		ui.show()

func hide_ui():
	if ui:
		ui.hide()

func add_item(item: Item, quantity: int = 1) -> int:
	return controller.add_item_to_inventory(item, quantity)

func remove_item(item_id: String, quantity: int = 1) -> int:
	return controller.remove_item_from_inventory(item_id, quantity)

func has_item(item_id: String, quantity: int = 1) -> bool:
	return inventory.has_item(item_id, quantity)
