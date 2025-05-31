extends Node
class_name State

var state_machine: StateMachine
var player: CharacterBody3D

func _ready():
	pass

# Méthodes virtuelles à override
func enter():
	pass

func exit():
	pass

func update(_delta):
	pass

func physics_update(_delta):
	pass

func handle_input(_event):
	pass
