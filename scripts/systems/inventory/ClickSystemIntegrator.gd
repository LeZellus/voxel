# scripts/systems/inventory/ClickSystemIntegrator.gd - VERSION AVEC LOGIQUE CORRIGÉE
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

# === GESTION DES CLICS - LOGIQUE SIMPLIFIÉE ===

func _handle_slot_click_via_events(context: ClickContext):
	"""Point d'entrée principal pour les clics - LOGIQUE CLARIFIÉE"""
	print("\n🎮 === CLIC DÉTECTÉ ===")
	print("   - Type: %s" % ClickContext.ClickType.keys()[context.click_type])
	print("   - Slot: %d" % context.source_slot_index)
	print("   - Container: %s" % context.source_container_id)
	print("   - Item: %s" % context.source_slot_data.get("item_name", "vide"))
	print("   - Quantité: %d" % context.source_slot_data.get("quantity", 0))
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	
	# LOGIQUE SIMPLIFIÉE : Deux cas seulement
	if not selected_slot_info.is_empty():
		# CAS 1: Le joueur a quelque chose en main
		_handle_placement_from_hand(context)
	else:
		# CAS 2: Nouveau clic (sélection ou utilisation)
		_handle_fresh_click(context)

func _handle_placement_from_hand(context: ClickContext):
	"""Gère le placement depuis la main - CONTEXTE CORRECT"""
	print("🔄 === PLACEMENT DEPUIS LA MAIN ===")
	
	var hand_data = selected_slot_info.slot_data
	print("   - Item en main: %s x%d" % [
		hand_data.get("item_name", "?"),
		hand_data.get("quantity", 0)
	])
	print("   - Destination: slot %d (%s)" % [
		context.source_slot_index,
		context.source_slot_data.get("item_name", "vide")
	])
	
	# CRÉER LE BON CONTEXTE : main → slot cliqué
	var placement_context = _create_hand_to_slot_context(context)
	
	# Envoyer directement au ActionRegistry
	if not click_system or not click_system.action_registry:
		print("❌ ActionRegistry introuvable!")
		_clear_selection()
		return
	
	print("🎯 Envoi vers ActionRegistry...")
	var success = click_system.action_registry.execute(placement_context)
	
	print("📊 Résultat: %s" % ("✅ Succès" if success else "❌ Échec"))
	
	# IMPORTANT: Ne clear que si c'est un placement réussi ou un échec définitif
	if success or context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
		_clear_selection()
	
	if success:
		call_deferred("_refresh_all_uis")

func _handle_fresh_click(context: ClickContext):
	"""Gère un nouveau clic - LOGIQUE CLARIFIÉE"""
	print("🎯 === NOUVEAU CLIC ===")
	
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			print("   - Type: Clic gauche")
			_handle_left_click_selection(context)
		
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			print("   - Type: Clic droit")
			_handle_right_click_action(context)

func _handle_left_click_selection(context: ClickContext):
	"""Gère la sélection avec clic gauche"""
	if context.source_slot_data.get("is_empty", true):
		print("⚠️ Slot vide - Affichage erreur")
		_show_error_feedback(context)
		return
	
	print("✅ Sélection du slot")
	_clear_visual_selection()
	_apply_visual_selection(context)
	_save_selection_data(context)
	_show_item_preview(context.source_slot_data)

func _handle_right_click_action(context: ClickContext):
	"""Gère les actions de clic droit (half-stack, usage...)"""
	print("🔨 Action clic droit...")
	
	if not click_system or not click_system.action_registry:
		print("❌ ActionRegistry introuvable!")
		return
	
	var success = click_system.action_registry.execute(context)
	print("📊 Résultat: %s" % ("✅ Succès" if success else "❌ Échec"))
	
	if success:
		call_deferred("_refresh_all_uis")

# === CRÉATION DE CONTEXTES CORRECTS ===

func _create_hand_to_slot_context(clicked_context: ClickContext) -> ClickContext:
	"""Crée un contexte main → slot SANS target_slot_index"""
	# IMPORTANT: On ne met pas de target_slot_index pour que HandPlacementAction le reconnaisse
	var hand_context = ClickContext.new()
	hand_context.click_type = clicked_context.click_type
	hand_context.source_slot_index = clicked_context.source_slot_index  # Le slot cliqué
	hand_context.source_container_id = clicked_context.source_container_id
	hand_context.source_slot_data = clicked_context.source_slot_data  # Données du slot cliqué
	hand_context.target_slot_index = -1  # IMPORTANT: Pas de target pour HandPlacementAction
	
	# Les données de la main ne sont pas dans le contexte mais récupérées via get_hand_data()
	return hand_context

# === GESTION VISUELLE (INCHANGÉ) ===

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
		"slot_data": context.source_slot_data.duplicate()  # IMPORTANT: Dupliquer pour éviter les refs
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

# === MÉTHODES PREVIEW (INCHANGÉ) ===

func _show_item_preview(item_data: Dictionary):
	"""Affiche la preview via PreviewManager"""
	PreviewManager.show_item_preview(item_data)

func _hide_item_preview():
	"""Cache la preview via PreviewManager"""
	PreviewManager.hide_item_preview()

# === UTILITAIRES ===

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	print("🔄 Rafraîchissement de toutes les UIs...")
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
			print("  ✅ UI %s rafraîchie" % container_id)

# === API PUBLIQUE (INCHANGÉ) ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui
		print("✅ Container %s enregistré avec UI" % container_id)

# === DEBUG (INCHANGÉ) ===

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
