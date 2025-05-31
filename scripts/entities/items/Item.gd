# scripts/inventory/data/Item.gd
class_name Item
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var max_stack_size: int = 1
@export var is_stackable: bool = false
@export var item_type: ItemType = ItemType.CONSUMABLE

enum ItemType {
	CONSUMABLE,
	TOOL,
	RESOURCE,
	EQUIPMENT
}

func _init(item_id: String = "", item_name: String = ""):
	id = item_id
	name = item_name
	is_stackable = max_stack_size > 1
