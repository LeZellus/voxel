# scripts/click_system/core/ClickSystemManager.gd
class_name ClickSystemManager
extends Node

# === SIGNAUX ===
signal action_executed(action_name: String, success: bool, context: ClickContext)
signal click_interaction_started(context: ClickContext)
signal click_interaction_completed(context: ClickContext, success: bool)

# === REGISTRES ===
var registered_actions: Dictionary = {}  # ClickType -> Array[ClickAction]
var registered_containers: Dictionary = {}  # container_id -> InventoryController
var click_history: Array[ClickContext] = []
var max_history_size: int = 50

# === ÉTAT DU SYSTÈME ===
var is_waiting_for_target: bool = false
var pending_context: ClickContext = null
var double_click_time: float = 0.3
var last_click_time: float = 0.0
var last_clicked_slot: Dictionary = {}  # Pour détecter les double-clics

func _ready():
	print("🎮 ClickSystemManager initialisé")
	_register_default_actions()

# === ENREGISTREMENT DES ACTIONS ===

func register_action(click_type: ClickContext.ClickType, action: ClickAction):
	"""Enregistre une action pour un type de clic"""
	if not registered_actions.has(click_type):
		registered_actions[click_type] = []
	
	registered_actions[click_type].append(action)
	
	# Connecter les signaux de l'action
	action.action_completed.connect(_on_action_completed)
	action.action_cancelled.connect(_on_action_cancelled)
	
	print("🎮 Action enregistrée: %s pour %s" % [action.action_name, ClickContext.ClickType.keys()[click_type]])

func register_container(container_id: String, controller: InventoryController):
	"""Enregistre un conteneur d'inventaire"""
	registered_containers[container_id] = controller
	print("🎮 Conteneur enregistré: %s" % container_id)

# === GESTION DES CLICS ===

func handle_slot_click(slot_index: int, container_id: String, slot_data: Dictionary, mouse_event: InputEventMouseButton) -> bool:
	"""Point d'entrée principal pour les clics sur les slots"""
	
	var click_type = _determine_click_type(mouse_event, slot_index, container_id)
	var context = ClickContext.create_slot_interaction(click_type, slot_index, container_id, slot_data)
	
	print("🎮 Clic détecté: %s" % context.to_string())
	
	# Gestion spéciale pour les clics en attente de cible
	if is_waiting_for_target and pending_context:
		return _handle_target_click(context)
	
	return _execute_click_action(context)

func _determine_click_type(mouse_event: InputEventMouseButton, slot_index: int, container_id: String) -> ClickContext.ClickType:
	"""Détermine le type de clic en fonction de l'événement"""
	var current_time = Time.get_time_dict_from_system().get("unix", 0.0)
	
	# Détection du double-clic
	var is_double_click = false
	var slot_key = "%s_%d" % [container_id, slot_index]
	
	if last_clicked_slot.get("key") == slot_key:
		if current_time - last_click_time < double_click_time:
			is_double_click = true
	
	last_clicked_slot = {"key": slot_key}
	last_click_time = current_time
	
	# Déterminer le type selon les modificateurs
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if is_double_click:
			return ClickContext.ClickType.DOUBLE_LEFT_CLICK
		elif Input.is_key_pressed(KEY_SHIFT):
			return ClickContext.ClickType.SHIFT_LEFT_CLICK
		elif Input.is_key_pressed(KEY_CTRL):
			return ClickContext.ClickType.CTRL_LEFT_CLICK
		elif Input.is_key_pressed(KEY_ALT):
			return ClickContext.ClickType.ALT_LEFT_CLICK
		else:
			return ClickContext.ClickType.SIMPLE_LEFT_CLICK
	
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.is_key_pressed(KEY_SHIFT):
			return ClickContext.ClickType.SHIFT_RIGHT_CLICK
		elif Input.is_key_pressed(KEY_CTRL):
			return ClickContext.ClickType.CTRL_RIGHT_CLICK
		else:
			return ClickContext.ClickType.SIMPLE_RIGHT_CLICK
	
	elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
		return ClickContext.ClickType.MIDDLE_CLICK
	
	# Fallback
	return ClickContext.ClickType.SIMPLE_LEFT_CLICK

func _execute_click_action(context: ClickContext) -> bool:
	"""Exécute l'action appropriée pour le contexte donné"""
	click_interaction_started.emit(context)
	
	var actions = registered_actions.get(context.click_type, [])
	
	if actions.is_empty():
		print("⚠️ Aucune action enregistrée pour: %s" % ClickContext.ClickType.keys()[context.click_type])
		return false
	
	# Essayer les actions dans l'ordre jusqu'à ce qu'une puisse s'exécuter
	for action in actions:
		if action.can_execute(context):
			print("🎮 Exécution de l'action: %s" % action.action_name)
			
			action.action_started.emit(action.action_name, context)
			var success = action.execute(context)
			
			if success:
				_add_to_history(context)
				click_interaction_completed.emit(context, true)
				return true
			else:
				print("❌ Échec de l'action: %s" % action.action_name)
	
	click_interaction_completed.emit(context, false)
	return false

func _handle_target_click(target_context: ClickContext) -> bool:
	"""Gère le clic de destination quand on attend une cible"""
	if not pending_context:
		return false
	
	# Créer un contexte slot-to-slot
	var combined_context = ClickContext.create_slot_to_slot_interaction(
		pending_context.click_type,
		pending_context.source_slot_index,
		pending_context.source_container_id,
		pending_context.source_slot_data,
		target_context.source_slot_index,
		target_context.source_container_id,
		target_context.source_slot_data
	)
	
	# Réinitialiser l'état d'attente
	is_waiting_for_target = false
	var temp_context = pending_context
	pending_context = null
	
	print("🎮 Clic slot-to-slot: %s" % combined_context.to_string())
	
	return _execute_click_action(combined_context)

# === GESTION DES ACTIONS EN ATTENTE ===

func start_waiting_for_target(context: ClickContext):
	"""Démarre l'attente d'un clic de destination"""
	is_waiting_for_target = true
	pending_context = context
	print("⏳ En attente d'un clic de destination...")

func cancel_waiting_for_target():
	"""Annule l'attente d'un clic de destination"""
	if is_waiting_for_target and pending_context:
		print("❌ Annulation de l'attente de destination")
		is_waiting_for_target = false
		pending_context = null

# === UTILITAIRES ===

func get_controller_for_container(container_id: String) -> InventoryController:
	"""Récupère le contrôleur pour un conteneur"""
	return registered_containers.get(container_id)

func _add_to_history(context: ClickContext):
	"""Ajoute un contexte à l'historique"""
	click_history.append(context)
	
	if click_history.size() > max_history_size:
		click_history.pop_front()

# === GESTION DES SIGNAUX ===

func _on_action_completed(action_name: String, success: bool, context: ClickContext):
	action_executed.emit(action_name, success, context)

func _on_action_cancelled(action_name: String, context: ClickContext):
	if pending_context == context:
		cancel_waiting_for_target()

# === ACTIONS PAR DÉFAUT ===

func _register_default_actions():
	"""Enregistre les actions par défaut du système"""
	# Les actions seront ajoutées dans les prochains artéfacts
	print("🎮 Actions par défaut à enregistrer...")

# === DEBUG ===

func get_system_state() -> Dictionary:
	"""Retourne l'état actuel du système pour debug"""
	return {
		"waiting_for_target": is_waiting_for_target,
		"pending_context": pending_context.to_string() if pending_context else "none",
		"registered_actions_count": _count_total_actions(),
		"registered_containers": registered_containers.keys(),
		"history_size": click_history.size()
	}

func _count_total_actions() -> int:
	var total = 0
	for actions in registered_actions.values():
		total += actions.size()
	return total

func print_debug_info():
	var state = get_system_state()
	print("\n🎮 ClickSystemManager État:")
	for key in state.keys():
		print("   - %s: %s" % [key, state[key]])
