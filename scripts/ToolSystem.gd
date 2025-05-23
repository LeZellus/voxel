extends Node
class_name ToolSystem

enum Tool {
	SEEDS,
	WATERING_CAN,
	SICKLE
}

var current_tool: Tool = Tool.SEEDS
@onready var interaction_ray: RayCast3D = get_parent().get_node("SpringArm3D/InteractionRay")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Espace
		test_interaction()
	
	if event.is_action_pressed("ui_right"):
		current_tool = Tool.WATERING_CAN
		print("Changé vers: ARROSOIR")
	elif event.is_action_pressed("ui_left"):
		current_tool = Tool.SEEDS
		print("Changé vers: GRAINES")

func test_interaction():
	if interaction_ray.is_colliding():
		var hit_point = interaction_ray.get_collision_point()
		print("Interaction avec outil ", current_tool, " à la position: ", hit_point)
	else:
		print("Rien devant le joueur")
