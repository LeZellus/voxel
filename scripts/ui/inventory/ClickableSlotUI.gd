# scripts/ui/inventory/ClickableSlotUI.gd - AVEC INPUT STATE MANAGER
class_name ClickableSlotUI
extends Control

# === SIGNAUX ===
signal slot_action_detected(slot_index: int, action_type: InputStateManager.ActionType, context: Dictionary)

# === COMPOSANTS ===
var item_icon: TextureRect  
var quantity_label: Label
var button: Button
var visual_manager: SlotVisualManager

# === NOUVEAU : INPUT MANAGER ===
var input_manager: InputStateManager

# === DONNÉES ===
var slot_index: int = -1
var slot_data: Dictionary = {"is_empty": true}

func _ready():
	_initialize_components()

func _initialize_components():
	"""Initialise tous les composants du slot"""
	_find_ui_components()
	_setup_input_manager()  # NOUVEAU
	_setup_visual_manager()
	_setup_button()
	clear_slot()

func _find_ui_components():
	"""Trouve les composants UI existants"""
	item_icon = get_node_or_null("ItemIcon")
	quantity_label = get_node_or_null("QuantityLabel") 
	button = get_node_or_null("Button")

func _setup_input_manager():
	"""NOUVEAU : Configure le gestionnaire d'input avancé"""
	input_manager = InputStateManager.new()
	# Connecter le signal pour recevoir les actions détectées
	input_manager.action_detected.connect(_on_advanced_action_detected)

func _setup_visual_manager():
	"""Configure le gestionnaire visuel robuste"""
	visual_manager = SlotVisualManager.new(self)

func _setup_button():
	"""Configure le bouton de capture des clics"""
	if not button:
		return
	
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	
	_connect_button_signals()

func _connect_button_signals():
	"""Connecte les signaux du bouton - MODIFIÉ"""
	# REMPLACER l'ancien gui_input par le nouveau système
	if not button.gui_input.is_connected(_on_advanced_gui_input):
		button.gui_input.connect(_on_advanced_gui_input)
	if not button.mouse_entered.is_connected(_on_mouse_entered):
		button.mouse_entered.connect(_on_mouse_entered)
	if not button.mouse_exited.is_connected(_on_mouse_exited):
		button.mouse_exited.connect(_on_mouse_exited)

# === NOUVEAUX ÉVÉNEMENTS AVANCÉS ===

func _on_advanced_gui_input(event: InputEvent):
	"""NOUVEAU : Traitement d'input avancé via InputStateManager"""
	if not input_manager:
		return
	
	# Laisser l'InputStateManager analyser l'événement
	var action_type = input_manager.process_input(event)
	
	# Créer le contexte étendu pour cette action
	var context = {
		"slot_index": slot_index,
		"slot_data": slot_data.duplicate(),
		"mouse_position": event.global_position if event is InputEventMouse else Vector2.ZERO,
		"modifiers": input_manager.get_current_modifiers(),
		"is_dragging": input_manager.is_in_drag_state(),
		"is_holding": input_manager.is_in_hold_state()
	}
	
	# Émettre le signal avec le type d'action détecté
	slot_action_detected.emit(slot_index, action_type, context)
	
	# DEBUG
	if action_type != InputStateManager.ActionType.SIMPLE_LEFT_CLICK:  # Éviter le spam
		print("🎮 Slot[%d]: %s détecté" % [slot_index, InputStateManager.ActionType.keys()[action_type]])

func _on_advanced_action_detected(action_type: InputStateManager.ActionType, event: InputEvent, context: Dictionary):
	"""Callback quand l'InputStateManager détecte une action"""
	# Cette méthode peut être utilisée pour des traitements spécifiques au slot
	# Pour l'instant, on délègue tout via slot_action_detected
	pass

# === ÉVÉNEMENTS SOURIS (inchangés) ===

func _on_mouse_entered():
	"""Gestion du survol"""
	if visual_manager:
		visual_manager.set_hover_state(true)

func _on_mouse_exited():
	"""Fin du survol"""
	if visual_manager:
		visual_manager.set_hover_state(false)

# === API VISUELLE PUBLIQUE (inchangée) ===

func highlight_as_selected():
	"""Active la sélection visuelle"""
	if visual_manager:
		visual_manager.set_selected_state(true)

func remove_selection_highlight():
	"""Désactive la sélection visuelle"""
	if visual_manager:
		visual_manager.set_selected_state(false)
	
func show_error_feedback():
	"""Affiche le feedback d'erreur (action refusée)"""
	if visual_manager:
		visual_manager.show_error_feedback()

# === NOUVELLES MÉTHODES POUR ÉTATS AVANCÉS ===

func is_in_drag_sequence() -> bool:
	"""Vérifie si ce slot est dans une séquence de drag"""
	return input_manager and input_manager.is_in_drag_state()

func is_in_hold_sequence() -> bool:
	"""Vérifie si ce slot est dans une séquence de hold"""
	return input_manager and input_manager.is_in_hold_state()

func get_current_action_state() -> String:
	"""Retourne l'état actuel pour debug"""
	if not input_manager:
		return "no_manager"
	
	if input_manager.is_in_drag_state():
		return "dragging"
	elif input_manager.is_in_hold_state():
		return "holding"
	else:
		return "idle"

# === GESTION DES DONNÉES (inchangée) ===

func set_slot_index(index: int):
	slot_index = index

func get_slot_index() -> int:
	return slot_index

func update_slot(slot_info: Dictionary):
	"""Met à jour l'affichage du slot"""
	var old_data = slot_data.duplicate()
	slot_data = slot_info
	
	# DEBUG : Vérifier les changements significatifs
	var old_empty = old_data.get("is_empty", true)
	var new_empty = slot_info.get("is_empty", true)
	var old_qty = old_data.get("quantity", 0)
	var new_qty = slot_info.get("quantity", 0)
	
	if not new_empty and (old_empty or old_qty != new_qty):
		print("🔄 Slot[%d] update: %s x%d (était: %s x%d)" % [
			slot_index, 
			slot_info.get("item_name", "?"), new_qty,
			old_data.get("item_name", "?"), old_qty
		])
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		_display_item(slot_info)
	
	_force_visual_refresh()

func _display_item(slot_info: Dictionary):
	"""Affiche un item dans le slot"""
	_update_item_icon(slot_info)
	_update_quantity_label(slot_info)

func _update_item_icon(slot_info: Dictionary):
	"""Met à jour l'icône de l'item"""
	if not item_icon:
		return
	
	var icon_texture = slot_info.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		item_icon.visible = true
	else:
		item_icon.texture = null
		item_icon.visible = false

func _update_quantity_label(slot_info: Dictionary):
	"""Met à jour le label de quantité"""
	if not quantity_label:
		return
	
	var qty = slot_info.get("quantity", 1)
	
	if qty > 1:
		quantity_label.text = str(qty)
		quantity_label.visible = true
	else:
		quantity_label.text = ""
		quantity_label.visible = false

func clear_slot():
	"""Vide complètement le slot"""
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
		
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
		
	slot_data = {"is_empty": true}

func _force_visual_refresh():
	"""Force un redraw immédiat de tous les composants"""
	await get_tree().process_frame
	
	if item_icon:
		item_icon.queue_redraw()
	if quantity_label:
		quantity_label.queue_redraw()
	
	if get_parent():
		get_parent().queue_sort()

# === UTILITAIRES (inchangés) ===

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func get_slot_data() -> Dictionary:
	return slot_data.duplicate()

# === NETTOYAGE ===

func _exit_tree():
	"""Nettoyage à la destruction"""
	if visual_manager:
		visual_manager.cleanup()
	
	# NOUVEAU : Reset de l'input manager
	if input_manager:
		input_manager.reset_state()

# === DEBUG ÉTENDU ===

func debug_visual_state():
	"""Debug de l'état visuel"""
	if visual_manager:
		visual_manager.debug_state()
	else:
		print("❌ Pas de visual_manager")

func debug_input_state():
	"""NOUVEAU : Debug de l'état d'input"""
	if input_manager:
		print("🎮 Input state pour slot[%d]:" % slot_index)
		print("   - Action state: %s" % get_current_action_state())
		print("   - Modifiers: %s" % input_manager.get_current_modifiers())
	else:
		print("❌ Pas d'input_manager")

func debug_slot_content():
	"""Debug du contenu du slot"""
	print("🔍 Slot[%d] Debug:" % slot_index)
	print("   - Vide: %s" % slot_data.get("is_empty", true))
	print("   - Item: %s" % slot_data.get("item_name", "aucun"))
	print("   - Quantité: %d" % slot_data.get("quantity", 0))
	print("   - Input state: %s" % get_current_action_state())
	print("   - UI Icon visible: %s" % (item_icon.visible if item_icon else "N/A"))
	print("   - UI Label visible: %s" % (quantity_label.visible if quantity_label else "N/A"))
