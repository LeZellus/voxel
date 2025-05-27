# ItemPickup.gd - À attacher à votre Area3D de détection sur le Player
extends Area3D

@onready var inventory_manager = get_parent().get_node("InventoryManager")
var items_in_range: Array[RigidBody3D] = []

func _ready():
	body_entered.connect(_on_item_entered)
	body_exited.connect(_on_item_exited)

func _on_item_entered(body: Node3D):
	if body.has_method("pickup"):
		items_in_range.append(body)
		print("Item détecté: ", body.get_item_name())

func _on_item_exited(body: Node3D):
	if body in items_in_range:
		items_in_range.erase(body)

func _input(event):
	if event.is_action_pressed("interact") and items_in_range.size() > 0:
		pickup_nearest_item()

func pickup_nearest_item():
	if items_in_range.size() == 0:
		return
	
	var item_node = items_in_range[0]
	var item = item_node.pickup()  # Récupère l'item et supprime l'objet
	
	if item and inventory_manager:
		var remaining = inventory_manager.add_item_to_inventory(item, 1)
		if remaining > 0:
			print("Inventaire plein!")
		else:
			print("Item ajouté à l'inventaire: ", item.name)
			items_in_range.erase(item_node)
