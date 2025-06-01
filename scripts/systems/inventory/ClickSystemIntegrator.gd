# scripts/systems/inventory/ClickSystemIntegrator.gd - AVEC FEEDBACK D'ERREUR
class_name ClickSystemIntegrator
extends Node

# === COMPOSANTS ===
var click_system: ClickSystemManager
var registered_uis: Dictionary = {}
var selected_slot_info: Dictionary = {}
var currently_selected_slot_ui: ClickableSlotUI

func _ready():
	_initialize_system()

func _initialize_system():
	"""Initialise le système de clic"""
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	ServiceLocator.register("click_system", click_system)
	
	if Events.instance:
		Events.instance.slot_clicked.connect(_handle_slot_click_via_events)

# === GESTION DES CLICS ===

func _handle_slot_click_via_events(context: ClickContext):
	"""Point d'entrée principal pour les clics"""
	if not selected_slot_info.is_empty():
		_handle_transfer_attempt(context)
	else:
		_handle_initial_click(context)

func _handle_transfer_attempt(context: ClickContext):
	"""Gère une tentative de transfert"""
	print("🔄 Tentative de transfert...")
	
	var target_context = _create_slot_to_slot_context(context)
	var success = click_system.action_registry.execute(target_context)
	
	_clear_selection()
	
	if success:
		_refresh_all_uis()

func _handle_initial_click(context: ClickContext):
	"""Gère le premier clic sur un slot"""
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			_handle_selection(context)
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			_handle_usage(context)

func _handle_selection(context: ClickContext):
	"""Gère la sélection d'un slot (MODIFIÉ pour inclure feedback d'erreur)"""
	if context.source_slot_data.get("is_empty", true):
		# NOUVEAU: Slot vide - afficher feedback d'erreur
		_show_error_feedback(context)
		return
	
	_clear_visual_selection()
	_apply_visual_selection(context)
	_save_selection_data(context)

func _show_error_feedback(context: ClickContext):
	"""NOUVEAU: Affiche le feedback d'erreur sur un slot vide"""
	var slot_ui = SlotFinder.find_slot_ui_for_context(context, registered_uis)
	if slot_ui and slot_ui.has_method("show_error_feedback"):
		slot_ui.show_error_feedback()
		print("❌ Clic sur slot vide - feedback d'erreur affiché")

func _handle_usage(context: ClickContext):
	"""Gère l'utilisation directe d'un item"""
	var success = click_system.action_registry.execute(context)
	if success:
		call_deferred("_refresh_all_uis")

# === GESTION VISUELLE ===

func _clear_visual_selection():
	"""Nettoie la sélection visuelle précédente"""
	if currently_selected_slot_ui and is_instance_valid(currently_selected_slot_ui):
		currently_selected_slot_ui.remove_selection_highlight()

func _apply_visual_selection(context: ClickContext):
	"""Applique la sélection visuelle"""
	var slot_ui = SlotFinder.find_slot_ui_for_context(context, registered_uis)
	if slot_ui:
		slot_ui.highlight_as_selected()
		currently_selected_slot_ui = slot_ui
		print("✨ Sélection visuelle activée sur slot %d" % context.source_slot_index)

func _save_selection_data(context: ClickContext):
	"""Sauvegarde les données de sélection"""
	selected_slot_info = {
		"slot_index": context.source_slot_index,
		"container_id": context.source_container_id,
		"slot_data": context.source_slot_data
	}
	print("✅ Slot %d sélectionné (%s)" % [context.source_slot_index, context.source_slot_data.get("item_name", "Inconnu")])

func _clear_selection():
	"""Efface complètement la sélection"""
	if selected_slot_info.is_empty():
		return
	
	print("🔹 Sélection effacée slot %d" % selected_slot_info.slot_index)
	
	_clear_visual_selection()
	currently_selected_slot_ui = null
	selected_slot_info.clear()

# === UTILITAIRES ===

func _create_slot_to_slot_context(target_context: ClickContext) -> ClickContext:
	"""Crée un contexte de transfert slot-to-slot"""
	return ClickContext.create_slot_to_slot_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		selected_slot_info.slot_index,
		selected_slot_info.container_id, 
		selected_slot_info.slot_data,
		target_context.source_slot_index,
		target_context.source_container_id,
		target_context.source_slot_data
	)

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()

# === API PUBLIQUE ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui

func print_debug_info():
	"""Affiche l'état du système pour debug"""
	print("\n🔍 ÉTAT CLICK SYSTEM:")
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	if not selected_slot_info.is_empty():
		print("   - Slot sélectionné: %d dans %s" % [selected_slot_info.slot_index, selected_slot_info.container_id])
	print("   - UIs enregistrées: %d" % registered_uis.size())
