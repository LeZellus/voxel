class_name ClickSystemIntegrator
extends Node

var click_system: ClickSystemManager

func _ready():
	click_system = ClickSystemManager.new()
	add_child(click_system)
	_register_actions()

func _register_actions():
	var move_action = MoveItemAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_LEFT_CLICK, move_action)
	
	var use_action = UseItemAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_RIGHT_CLICK, use_action)
	
	var cross_action = CrossContainerAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_LEFT_CLICK, cross_action)

func register_container(container_id: String, controller, ui: Control):
	click_system.register_container(container_id, controller)
	# UI connection viendra plus tard
