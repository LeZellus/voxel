# scripts/inventory/containers/ChestContainer.gd
class_name ChestContainer
extends BaseContainer

var world_position: Vector3
var is_open: bool = false

func _init(chest_size: int = 27, pos: Vector3 = Vector3.ZERO):
	world_position = pos
	super("chest_" + str(pos), chest_size, "Coffre")

func can_access(player_pos: Vector3, max_distance: float = 3.0) -> bool:
	return world_position.distance_to(player_pos) <= max_distance

func open(player_pos: Vector3) -> bool:
	if can_access(player_pos):
		is_open = true
		return true
	return false

func close():
	is_open = false
