# scripts/systems/inventory/ClickSystemIntegrator.gd - VERSION CORRIGÉE
class_name ClickSystemIntegrator
extends Node

var click_system: ClickSystemManager
var registered_uis: Dictionary = {}
var selected_slot_info: Dictionary = {}

var currently_selected_slot_ui: ClickableSlotUI

func _ready():
	_setup_click_system()
	
	if Events.instance:
		Events.instance.slot_clicked.connect(_handle_slot_click_via_events)
	else:
		print("❌ Events non disponible")

func _setup_click_system():
	"""Configure le gestionnaire de clic"""
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	ServiceLocator.register("click_system", click_system)

func _handle_slot_click_via_events(context: ClickContext):
	"""Gestionnaire principal unifié"""
	print("🎮 Clic détecté - Slot sélectionné: %s" % (not selected_slot_info.is_empty()))
	
	# Si on a déjà un slot sélectionné = créer un contexte slot-to-slot
	if not selected_slot_info.is_empty():
		print("🔄 Tentative de transfert...")
		var target_context = _create_slot_to_slot_context(context)
		
		# Exécuter l'action avec le contexte complet
		var success = click_system.action_registry.execute(target_context)
		
		# CORRECTION CRUCIALE : Nettoyer la sélection après transfert
		_clear_selection()
		
		if success:
			# Rafraîchissement immédiat et forcé
			_refresh_all_uis()
		return
	
	# Premier clic = gérer selon le type
	match context.click_type:
		ClickContext.ClickType.SIMPLE_LEFT_CLICK:
			_handle_left_click(context)
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			_handle_right_click(context)

func _handle_left_click(context: ClickContext):
	"""Gère les clics gauches avec feedback visuel"""
	if context.source_slot_data.get("is_empty", true):
		print("🔹 Slot vide cliqué - pas de sélection")
		return
	
	# Nettoyer l'ancienne sélection visuelle
	if currently_selected_slot_ui and is_instance_valid(currently_selected_slot_ui):
		currently_selected_slot_ui.remove_selection_highlight()
	
	# Trouver le nouveau slot UI et l'activer
	var slot_ui = _find_slot_ui_for_context(context)
	if slot_ui:
		slot_ui.highlight_as_selected()
		currently_selected_slot_ui = slot_ui
		print("✨ Sélection visuelle activée sur slot %d" % context.source_slot_index)
	
	# Sélectionner le slot (logique)
	selected_slot_info = {
		"slot_index": context.source_slot_index,
		"container_id": context.source_container_id,
		"slot_data": context.source_slot_data
	}
	print("✅ Slot %d sélectionné (%s)" % [context.source_slot_index, context.source_slot_data.get("item_name", "Inconnu")])

func _handle_right_click(context: ClickContext):
	"""Gère les clics droits (utilisation directe)"""
	print("🖱️ Clic droit - utilisation directe")
	var success = click_system.action_registry.execute(context)
	if success:
		call_deferred("_refresh_all_uis")

func _create_slot_to_slot_context(target_context: ClickContext) -> ClickContext:
	"""Crée un contexte slot-to-slot pour le déplacement"""
	print("📦 Création contexte transfert: %d -> %d" % [selected_slot_info.slot_index, target_context.source_slot_index])
	return ClickContext.create_slot_to_slot_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		selected_slot_info.slot_index,
		selected_slot_info.container_id, 
		selected_slot_info.slot_data,
		target_context.source_slot_index,
		target_context.source_container_id,
		target_context.source_slot_data
	)

func _clear_selection():
	"""Efface la sélection (logique + visuel)"""
	if selected_slot_info.is_empty():
		return
	
	print("🔹 Sélection effacée slot %d" % selected_slot_info.slot_index)
	
	# Nettoyer le visuel
	if currently_selected_slot_ui and is_instance_valid(currently_selected_slot_ui):
		currently_selected_slot_ui.remove_selection_highlight()
	currently_selected_slot_ui = null
	
	# Nettoyer la logique
	selected_slot_info.clear()

# === ENREGISTREMENT (API identique) ===

func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	click_system.register_container(container_id, controller)
	
	if ui:
		registered_uis[container_id] = ui

# === UTILITAIRES ===

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	print("🔄 Rafraîchissement de toutes les UIs...")
	
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
			print("   ✅ UI rafraîchie: %s" % container_id)
		else:
			print("   ❌ UI non rafraîchie: %s" % container_id)

# === NOUVELLE MÉTHODE DEBUG ===
func print_debug_info():
	"""Affiche l'état du système de clic"""
	print("\n🔍 ÉTAT CLICK SYSTEM:")
	print("   - Sélection active: %s" % (not selected_slot_info.is_empty()))
	if not selected_slot_info.is_empty():
		print("   - Slot sélectionné: %d dans %s" % [selected_slot_info.slot_index, selected_slot_info.container_id])
	print("   - UIs enregistrées: %d" % registered_uis.size())
	for container_id in registered_uis.keys():
		print("     * %s" % container_id)
		
func _find_slot_ui_for_context(context: ClickContext) -> ClickableSlotUI:
	"""Trouve le ClickableSlotUI correspondant au contexte"""
	var ui = registered_uis.get(context.source_container_id)
	if not ui:
		return null
	
	return _find_slot_ui_in_container(ui, context.source_slot_index)

func _find_slot_ui_in_container(ui: Control, slot_index: int) -> ClickableSlotUI:
	"""Trouve un slot spécifique dans une UI container"""
	var slots = _find_all_slots_in_ui(ui)
	for slot in slots:
		if slot.get_slot_index() == slot_index:
			return slot
	return null

func _find_all_slots_in_ui(ui: Control) -> Array[ClickableSlotUI]:
	"""Trouve tous les ClickableSlotUI dans une UI"""
	var slots: Array[ClickableSlotUI] = []
	_find_slots_recursive(ui, slots)
	return slots

func _find_slots_recursive(node: Node, slots: Array[ClickableSlotUI]):
	"""Recherche récursive de ClickableSlotUI"""
	if node is ClickableSlotUI:
		slots.append(node as ClickableSlotUI)
	
	for child in node.get_children():
		_find_slots_recursive(child, slots)
