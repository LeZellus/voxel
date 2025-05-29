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
	elif event.is_action_pressed("ui_left"):
		current_tool = Tool.SEEDS
