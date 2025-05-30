# scripts/inventory/containers/PlayerInventory.gd
class_name PlayerInventory
extends BaseContainer

func _init():
	super("player_inventory", Constants.INVENTORY_SIZE, "Inventaire")

func setup_ui(ui_scene: PackedScene, parent: Node):
	ui = ui_scene.instantiate()
	parent.add_child(ui)
	
	if ui.has_method("setup_inventory"):
		ui.setup_inventory(inventory, controller)
