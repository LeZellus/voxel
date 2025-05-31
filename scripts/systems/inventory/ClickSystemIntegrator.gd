# scripts/systems/inventory/ClickSystemIntegrator.gd - VERSION CORRIGÉE
class_name ClickSystemIntegrator
extends Node

var click_system: ClickSystemManager
var registered_uis: Dictionary = {}
var selected_slot_info: Dictionary = {}

func _ready():
	_setup_click_system()
	
	if Events.instance:
		Events.instance.slot_clicked.connect(_handle_slot_click_via_events)
		print("🔗 ClickSystemIntegrator connecté aux Events")
	else:
		print("❌ Events non disponible")

func _setup_click_system():
	"""Configure le gestionnaire de clic"""
	click_system = ClickSystemManager.new()
	add_child(click_system)
	print("✅ ClickSystemIntegrator configuré")

func _handle_slot_click_via_events(context: ClickContext):
	"""Gestionnaire principal unifié"""
	print("🎯 Clic reçu: slot %d, container %s" % [context.source_slot_index, context.source_container_id])
	
	# Si on a déjà un slot sélectionné = créer un contexte slot-to-slot
	if not selected_slot_info.is_empty():
		var target_context = _create_slot_to_slot_context(context)
		_clear_selection()
		
		# Exécuter l'action avec le contexte complet
		var success = click_system.action_registry.execute(target_context)
		if success:
			# Rafraîchissement immédiat et forcé
			print("🔄 [INTEGRATOR] Forçage rafraîchissement après succès")
			_refresh_all_uis()
		return
	
	# Premier clic = gérer selon le type
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			_handle_left_click(context)
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			_handle_right_click(context)

func _handle_left_click(context: ClickContext):
	"""Gère les clics gauches (sélection/déplacement)"""
	if context.source_slot_data.get("is_empty", true):
		print("⚠️ Clic sur slot vide - ignoré")
		return
	
	# Sélectionner le slot
	selected_slot_info = {
		"slot_index": context.source_slot_index,
		"container_id": context.source_container_id,
		"slot_data": context.source_slot_data
	}
	
	_highlight_selected_slot()
	print("📌 Slot %d sélectionné - cliquez sur la destination" % context.source_slot_index)

func _handle_right_click(context: ClickContext):
	"""Gère les clics droits (utilisation directe)"""
	var success = click_system.action_registry.execute(context)
	if success:
		call_deferred("_refresh_all_uis")

func _create_slot_to_slot_context(target_context: ClickContext) -> ClickContext:
	"""Crée un contexte slot-to-slot pour le déplacement"""
	return ClickContext.create_slot_to_slot_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		selected_slot_info.slot_index,
		selected_slot_info.container_id, 
		selected_slot_info.slot_data,
		target_context.source_slot_index,
		target_context.source_container_id,
		target_context.source_slot_data
	)

# === SÉLECTION VISUELLE ===

func _highlight_selected_slot():
	"""Surligne visuellement le slot sélectionné"""
	if selected_slot_info.is_empty():
		return
	
	var ui = registered_uis.get(selected_slot_info.container_id)
	if not ui:
		return
	
	var slot_ui = _find_slot_ui(ui, selected_slot_info.slot_index)
	if slot_ui and slot_ui.has_method("set_selected"):
		slot_ui.set_selected(true)
		print("✨ Slot %d surligné" % selected_slot_info.slot_index)

func _clear_selection():
	"""Efface la sélection visuelle"""
	if selected_slot_info.is_empty():
		return
	
	var ui = registered_uis.get(selected_slot_info.container_id)
	if ui:
		var slot_ui = _find_slot_ui(ui, selected_slot_info.slot_index)
		if slot_ui and slot_ui.has_method("set_selected"):
			slot_ui.set_selected(false)
			print("🔹 Sélection effacée slot %d" % selected_slot_info.slot_index)
	
	selected_slot_info.clear()

# === ENREGISTREMENT (API identique) ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui
	
	print("🔗 Container connecté: %s" % container_id)

# === UTILITAIRES ===

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	print("🔄 [INTEGRATOR] Rafraîchissement de toutes les UIs...")
	
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
			print("   ✅ UI rafraîchie: %s" % container_id)
		else:
			print("   ❌ UI non rafraîchie: %s" % container_id)

func _find_slot_ui(ui: Control, slot_index: int) -> ClickableSlotUI:
	"""Trouve le ClickableSlotUI avec l'index donné"""
	var slots = _find_slots_in_ui(ui)
	for slot in slots:
		if slot.get_slot_index() == slot_index:
			return slot
	return null

func _find_slots_in_ui(ui: Control) -> Array:
	"""Trouve tous les ClickableSlotUI dans une UI"""
	var slots = []
	_find_slots_recursive(ui, slots)
	return slots

func _find_slots_recursive(node: Node, slots: Array):
	"""Recherche récursive de ClickableSlotUI"""
	if node is ClickableSlotUI:
		slots.append(node)
	
	for child in node.get_children():
		_find_slots_recursive(child, slots)

# === DEBUG ===

func debug_system():
	print("\n🔗 ClickSystemIntegrator:")
	print("   - UIs enregistrées: %s" % registered_uis.keys())
	print("   - Slot sélectionné: %s" % (not selected_slot_info.is_empty()))
	
	if click_system:
		click_system.print_debug_info()
