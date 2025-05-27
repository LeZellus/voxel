extends Node
class_name ToolSystem

enum Tool {
	SEEDS,
	WATERING_CAN,
	SICKLE
}

var current_tool: Tool = Tool.SEEDS

func _input(event):
	
	if event.is_action_pressed("ui_right"):
		current_tool = Tool.WATERING_CAN
		print("Changé vers: ARROSOIR")
	elif event.is_action_pressed("ui_left"):
		current_tool = Tool.SEEDS
		print("Changé vers: GRAINES")
