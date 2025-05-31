# scripts/click_system/core/ClickAction.gd
class_name ClickAction
extends RefCounted

# === INTERFACE POUR TOUTES LES ACTIONS DE CLIC ===

signal action_started(action_name: String, context: ClickContext)
signal action_completed(action_name: String, success: bool, context: ClickContext)
signal action_cancelled(action_name: String, context: ClickContext)

var action_name: String = "unknown_action"
var can_undo: bool = false
var requires_confirmation: bool = false

# === MÉTHODES VIRTUELLES À OVERRIDE ===

func can_execute(context: ClickContext) -> bool:
	"""Vérifie si l'action peut être exécutée avec ce contexte"""
	push_error("can_execute() doit être implémentée dans " + get_script().resource_path)
	return false

func execute(context: ClickContext) -> bool:
	"""Exécute l'action avec le contexte donné"""
	push_error("execute() doit être implémentée dans " + get_script().resource_path)
	return false

func undo(context: ClickContext) -> bool:
	"""Annule l'action (si supporté)"""
	if not can_undo:
		return false
	push_error("undo() doit être implémentée dans " + get_script().resource_path)
	return false

func get_description(context: ClickContext) -> String:
	"""Retourne une description de l'action pour debug/UI"""
	return action_name

func get_feedback_message(context: ClickContext, success: bool) -> String:
	"""Message de feedback pour l'utilisateur"""
	if success:
		return "Action réussie"
	else:
		return "Action échouée"

# === MÉTHODES UTILITAIRES ===

func get_source_controller(context: ClickContext, system_manager) -> ClickableInventoryController:
	"""Récupère le contrôleur du conteneur source"""
	return system_manager.get_controller_for_container(context.source_container_id)

func get_target_controller(context: ClickContext, system_manager) -> ClickableInventoryController:
	"""Récupère le contrôleur du conteneur cible"""
	return system_manager.get_controller_for_container(context.target_container_id)

func log_action(context: ClickContext, message: String):
	"""Log avec formatage standard"""
	print("🎮 [%s] %s - %s" % [action_name, context._to_string(), message])

# === VALIDATIONS COMMUNES ===

func validate_source_slot(context: ClickContext) -> bool:
	"""Valide que le slot source est valide"""
	return context.source_slot_index >= 0 and not context.source_container_id.is_empty()

func validate_target_slot(context: ClickContext) -> bool:
	"""Valide que le slot cible est valide (pour actions slot-to-slot)"""
	return context.target_slot_index >= 0 and not context.target_container_id.is_empty()

func validate_has_source_item(context: ClickContext) -> bool:
	"""Valide qu'il y a un item dans le slot source"""
	return context.has_source_item()

func emit_action_signals(context: ClickContext, success: bool):
	"""Émet les signaux appropriés selon le résultat"""
	if success:
		action_completed.emit(action_name, true, context)
		log_action(context, "✅ Action réussie")
	else:
		action_completed.emit(action_name, false, context)
		log_action(context, "❌ Action échouée")
