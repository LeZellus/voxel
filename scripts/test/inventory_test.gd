extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Test basique
	var apple = Item.new("apple", "Pomme")
	apple.max_stack_size = 10
	apple.is_stackable = true

	var slot = InventorySlot.new(0)
	var surplus = slot.add_item(apple, 5)
	print("Ajouté 5 pommes, surplus: ", surplus)
	print("Slot contient: ", slot.get_quantity(), " ", slot.get_item().name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
