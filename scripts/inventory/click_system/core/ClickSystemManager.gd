# scripts/inventory/click_system/core/ClickSystemManager.gd - VERSION REFACTORISÉE
class_name ClickSystemManager
extends Node

# === COMPOSANTS SIMPLES ===
var containers: Dictionary = {}
var action_registry: ActionRegistry
var pending_context: ClickContext

func _ready():
	print("🎮 ClickSystemManager refactorisé")
	action_registry = ActionRegistry.new()
	action_registry.setup_defaults()

# === ENREGISTREMENT CONTAINERS (API identique) ===
func register_container(container_id: String, controller):
	# Créer un wrapper simple pour garder compatibilité
	var container = SimpleContainer.new(container_id, controller)
	containers[container_id] = container
	print("📦 Container enregistré: %s" % container_id)

# === GESTION CLICS (API identique) ===
func handle_slot_click(slot_index: int, container_id: String, slot_data: Dictionary, mouse_event: InputEventMouseButton) -> bool:
	var click_type = _get_click_type(mouse_event)
	var context = ClickContext.create_slot_interaction(click_type, slot_index, container_id, slot_data)
	
	# Gestion cible en attente
	if pending_context:
		context = _create_target_context(context)
		pending_context = null
	
	return action_registry.execute(context)

func start_waiting_for_target(context: ClickContext):
	pending_context = context

# === GETTERS (API identique) ===
func get_controller_for_container(container_id: String):
	var container = containers.get(container_id)
	return container.controller if container else null

# === UTILITAIRES ===
func _get_click_type(event: InputEventMouseButton) -> ClickContext.ClickType:
	if event.button_index == MOUSE_BUTTON_RIGHT:
		return ClickContext.ClickType.SIMPLE_RIGHT_CLICK
	return ClickContext.ClickType.SIMPLE_LEFT_CLICK

func _create_target_context(target: ClickContext) -> ClickContext:
	return ClickContext.create_slot_to_slot_interaction(
		pending_context.click_type,
		pending_context.source_slot_index, pending_context.source_container_id, pending_context.source_slot_data,
		target.source_slot_index, target.source_container_id, target.source_slot_data
	)

func print_debug_info():
	print("🎮 ClickSystemManager (refactorisé):")
	print("   - Containers: %s" % containers.keys())
	print("   - En attente: %s" % (pending_context != null))

# === WRAPPER POUR COMPATIBILITÉ ===
class SimpleContainer:
	var id: String
	var controller
	
	func _init(container_id: String, ctrl):
		id = container_id
		controller = ctrl
