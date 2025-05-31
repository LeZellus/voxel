class_name ActionHandler
extends RefCounted

# === INTERFACE SIMPLE POUR TOUTES LES ACTIONS ===

var action_name: String
var priority: int = 0  # Plus élevé = plus prioritaire

func _init(name: String = "unknown", action_priority: int = 0):
	action_name = name
	priority = action_priority

# === MÉTHODES VIRTUELLES ===

func can_handle(context: ClickContext) -> bool:
	"""Vérifie si cette action peut gérer ce contexte"""
	return false

func execute(context: ClickContext) -> bool:
	"""Exécute l'action - retourne true si succès"""
	return false

func get_description(context: ClickContext) -> String:
	"""Description de l'action pour debug/UI"""
	return action_name

# === UTILITAIRES COMMUNS ===

func log(message: String):
	"""Log avec nom de l'action"""
	print("🎮 [%s] %s" % [action_name, message])

func get_source_item(context: ClickContext) -> Dictionary:
	"""Récupère les données de l'item source"""
	return context.source_slot_data

func get_target_item(context: ClickContext) -> Dictionary:
	"""Récupère les données de l'item cible"""
	return context.target_slot_data

func has_source_item(context: ClickContext) -> bool:
	"""Vérifie qu'il y a un item source"""
	return not context.source_slot_data.get("is_empty", true)

func has_target_item(context: ClickContext) -> bool:
	"""Vérifie qu'il y a un item cible"""
	return not context.target_slot_data.get("is_empty", true)
