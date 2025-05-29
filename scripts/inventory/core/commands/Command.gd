# scripts/inventory/core/commands/Command.gd
class_name Command
extends RefCounted

# Interface pour toutes les commandes d'inventaire

func execute() -> bool:
	push_error("execute() must be implemented in " + get_script().resource_path)
	return false

func undo() -> bool:
	push_error("undo() must be implemented in " + get_script().resource_path)
	return false

func can_execute() -> bool:
	return true

func get_description() -> String:
	return "Generic Command"
