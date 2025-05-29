# scripts/inventory/core/CommandSystem.gd
class_name CommandSystem
extends RefCounted

signal command_executed(command: Command)
signal command_undone(command: Command)

var history: Array[Command] = []
var current_index: int = -1
var max_history_size: int = 50

func execute(command: Command) -> bool:
	if not command.can_execute():
		print("❌ Commande non exécutable: ", command.get_description())
		return false
	
	if not command.execute():
		print("❌ Échec d'exécution: ", command.get_description())
		return false
	
	# Nettoie l'historique après l'index actuel (pour les nouveaux embranchements)
	_trim_history_after_current()
	
	# Ajoute la commande à l'historique
	history.append(command)
	current_index += 1
	
	# Limite la taille de l'historique
	_trim_history_size()
	
	command_executed.emit(command)
	print("✅ Commande exécutée: ", command.get_description())
	return true

func undo() -> bool:
	if not can_undo():
		print("❌ Aucune commande à annuler")
		return false
	
	var command = history[current_index]
	if not command.undo():
		print("❌ Échec d'annulation: ", command.get_description())
		return false
	
	current_index -= 1
	command_undone.emit(command)
	print("⏪ Commande annulée: ", command.get_description())
	return true

func redo() -> bool:
	if not can_redo():
		print("❌ Aucune commande à refaire")
		return false
	
	current_index += 1
	var command = history[current_index]
	
	if not command.execute():
		current_index -= 1
		print("❌ Échec de réexécution: ", command.get_description())
		return false
	
	command_executed.emit(command)
	print("⏩ Commande refaite: ", command.get_description())
	return true

func can_undo() -> bool:
	return current_index >= 0

func can_redo() -> bool:
	return current_index < history.size() - 1

func clear_history():
	history.clear()
	current_index = -1

func get_history_size() -> int:
	return history.size()

func _trim_history_after_current():
	if current_index < history.size() - 1:
		history = history.slice(0, current_index + 1)

func _trim_history_size():
	if history.size() > max_history_size:
		var excess = history.size() - max_history_size
		history = history.slice(excess)
		current_index -= excess
