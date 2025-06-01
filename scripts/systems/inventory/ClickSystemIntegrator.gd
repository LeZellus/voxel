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
	"""Gère le placement depuis la main - LOGIQUE CORRIGÉE"""
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
	
	# CORRECTION : Utiliser la nouvelle logique de création de contexte
	var placement_context = _create_hand_to_slot_context(context)
	
	print("   🔧 Contexte créé: %s" % placement_context._to_string())
	
	# Envoyer au ActionRegistry
	if not click_system or not click_system.action_registry:
		print("❌ ActionRegistry introuvable!")
		_clear_selection()
		return
	
	print("🎯 Envoi vers ActionRegistry...")
	var success = click_system.action_registry.execute(placement_context)
	
	print("📊 Résultat: %s" % ("✅ Succès" if success else "❌ Échec"))
	
	if success or context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
		_clear_selection()
	
	if success:
		call_deferred("_refresh_all_uis")
func _handle_direct_slot_to_slot(source_context: ClickContext, target_context: ClickContext):
	"""NOUVEAU : Gère les déplacements directs slot → slot"""
	print("🔄 === DÉPLACEMENT DIRECT SLOT → SLOT ===")
	
	var direct_context = ClickContext.create_slot_to_slot_interaction(
		source_context.click_type,
		source_context.source_slot_index, source_context.source_container_id, source_context.source_slot_data,
		target_context.source_slot_index, target_context.source_container_id, target_context.source_slot_data
	)
	
	if click_system and click_system.action_registry:
		var success = click_system.action_registry.execute(direct_context)
		if success:
			call_deferred("_refresh_all_uis")
		return success
	
	return false
	
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
	"""Crée un contexte main → slot CORRIGÉ"""
	var hand_data = selected_slot_info.slot_data
	var hand_item_id = hand_data.get("item_id", "")
	var target_item_id = clicked_context.source_slot_data.get("item_id", "")
	var target_empty = clicked_context.source_slot_data.get("is_empty", true)
	
	# CORRECTION : Créer le bon contexte selon la situation
	if not target_empty and hand_item_id == target_item_id and hand_item_id != "":
		# CAS RESTACK : Créer un contexte main → slot pour RestackAction
		print("🔧 Création contexte RESTACK main → slot")
		
		var restack_context = ClickContext.new()
		restack_context.click_type = clicked_context.click_type
		restack_context.source_slot_index = -1  # Main
		restack_context.source_container_id = "player_hand"
		restack_context.source_slot_data = hand_data
		restack_context.target_slot_index = clicked_context.source_slot_index  # Slot cliqué
		restack_context.target_container_id = clicked_context.source_container_id
		restack_context.target_slot_data = clicked_context.source_slot_data
		
		return restack_context
	else:
		# CAS PLACEMENT NORMAL : Contexte pour HandPlacementAction
		print("🔧 Création contexte PLACEMENT normal")
		
		var placement_context = ClickContext.new()
		placement_context.click_type = clicked_context.click_type
		placement_context.source_slot_index = clicked_context.source_slot_index  # Slot cliqué
		placement_context.source_container_id = clicked_context.source_container_id
		placement_context.source_slot_data = clicked_context.source_slot_data
		placement_context.target_slot_index = -1  # Pas de target pour HandPlacementAction
		
		return placement_context

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
