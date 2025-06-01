# scripts/systems/inventory/ClickSystemIntegrator.gd - VERSION AVEC DEBUG COMPLET
class_name ClickSystemIntegrator
extends Node

# === COMPOSANTS PRINCIPAUX ===
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
		print("✅ Events.slot_clicked connecté à ClickSystemIntegrator")

# === GESTION DES CLICS ===

func _handle_slot_click_via_events(context: ClickContext):
	"""Point d'entrée principal pour les clics - AVEC DEBUG COMPLET"""
	print("\n🎮 === CLIC DÉTECTÉ ===")
	print("   - Type: %s" % ClickContext.ClickType.keys()[context.click_type])
	print("   - Slot: %d" % context.source_slot_index)
	print("   - Container: %s" % context.source_container_id)
	print("   - Item: %s" % context.source_slot_data.get("item_name", "vide"))
	print("   - Quantité: %d" % context.source_slot_data.get("quantity", 0))
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	
	if not selected_slot_info.is_empty():
		print("   - Item en main: %s x%d" % [
			selected_slot_info.slot_data.get("item_name", "?"),
			selected_slot_info.slot_data.get("quantity", 0)
		])
		_handle_transfer_attempt(context)
	else:
		_handle_initial_click(context)

func _handle_transfer_attempt(context: ClickContext):
	"""Gère une tentative de transfert - AVEC DEBUG"""
	print("🔄 === TENTATIVE DE TRANSFERT ===")
	
	var target_context = _create_slot_to_slot_context(context)
	
	print("   - Source: %s[%d] - %s x%d" % [
		target_context.source_container_id,
		target_context.source_slot_index,
		target_context.source_slot_data.get("item_name", "?"),
		target_context.source_slot_data.get("quantity", 0)
	])
	print("   - Target: %s[%d] - %s x%d" % [
		target_context.target_container_id,
		target_context.target_slot_index,
		target_context.target_slot_data.get("item_name", "vide"),
		target_context.target_slot_data.get("quantity", 0)
	])
	
	# VÉRIFICATION CRITIQUE: Le ActionRegistry existe-t-il ?
	if not click_system or not click_system.action_registry:
		print("❌ ActionRegistry introuvable!")
		_clear_selection()
		return
	
	print("🎯 Envoi vers ActionRegistry...")
	var success = click_system.action_registry.execute(target_context)
	
	print("📊 Résultat action: %s" % ("✅ Succès" if success else "❌ Échec"))
	
	_clear_selection()
	
	if success:
		_refresh_all_uis()

func _handle_initial_click(context: ClickContext):
	"""Gère le premier clic sur un slot - AVEC DEBUG"""
	print("🎯 === CLIC INITIAL ===")
	
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			print("   - Type: Clic gauche - Sélection")
			_handle_selection(context)
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			print("   - Type: Clic droit - Utilisation")
			_handle_usage(context)

func _handle_selection(context: ClickContext):
	"""Gère la sélection d'un slot - AVEC DEBUG"""
	if context.source_slot_data.get("is_empty", true):
		print("⚠️ Slot vide - Affichage erreur")
		_show_error_feedback(context)
		return
	
	print("✅ Sélection du slot")
	_clear_visual_selection()
	_apply_visual_selection(context)
	_save_selection_data(context)
	_show_item_preview(context.source_slot_data)

func _handle_usage(context: ClickContext):
	"""Gère l'utilisation directe d'un item - AVEC DEBUG"""
	print("🔨 Tentative d'utilisation...")
	
	# VÉRIFICATION CRITIQUE
	if not click_system or not click_system.action_registry:
		print("❌ ActionRegistry introuvable pour usage!")
		return
	
	var success = click_system.action_registry.execute(context)
	print("📊 Résultat usage: %s" % ("✅ Succès" if success else "❌ Échec"))
	
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

func _save_selection_data(context: ClickContext):
	"""Sauvegarde les données de sélection"""
	selected_slot_info = {
		"slot_index": context.source_slot_index,
		"container_id": context.source_container_id,
		"slot_data": context.source_slot_data
	}
	
	print("💾 Sélection sauvegardée: %s x%d" % [
		context.source_slot_data.get("item_name", "?"),
		context.source_slot_data.get("quantity", 0)
	])

func _clear_selection():
	"""Efface complètement la sélection"""
	if selected_slot_info.is_empty():
		return
	
	print("🧹 Nettoyage sélection")
	_clear_visual_selection()
	currently_selected_slot_ui = null
	selected_slot_info.clear()
	_hide_item_preview()

func _show_error_feedback(context: ClickContext):
	"""Affiche le feedback d'erreur sur un slot vide"""
	var slot_ui = SlotFinder.find_slot_ui_for_context(context, registered_uis)
	if slot_ui and slot_ui.has_method("show_error_feedback"):
		slot_ui.show_error_feedback()

# === MÉTHODES PREVIEW ===

func _show_item_preview(item_data: Dictionary):
	"""Affiche la preview via PreviewManager"""
	PreviewManager.show_item_preview(item_data)

func _hide_item_preview():
	"""Cache la preview via PreviewManager"""
	PreviewManager.hide_item_preview()

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
	print("🔄 Rafraîchissement de toutes les UIs...")
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
			print("  ✅ UI %s rafraîchie" % container_id)

# === API PUBLIQUE ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui
		print("✅ Container %s enregistré avec UI" % container_id)

# === DEBUG ===

func debug_system_state():
	"""Debug complet du système"""
	print("\n🔍 === DEBUG CLICK SYSTEM ===")
	print("   - ClickSystemManager: %s" % ("✅" if click_system else "❌"))
	print("   - ActionRegistry: %s" % ("✅" if click_system and click_system.action_registry else "❌"))
	print("   - UIs enregistrées: %d" % registered_uis.size())
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	
	if click_system and click_system.action_registry:
		print("   - Actions disponibles: %d" % click_system.action_registry.actions.size())
		for action in click_system.action_registry.actions:
			print("     * %s (priorité: %d)" % [action.name, action.priority])
