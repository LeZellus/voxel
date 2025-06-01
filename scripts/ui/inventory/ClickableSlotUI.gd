# scripts/ui/inventory/ClickableSlotUI.gd - VERSION AVEC MISE À JOUR FORCÉE
class_name ClickableSlotUI
extends Control

# === SIGNAUX ===
signal slot_clicked(slot_index: int, mouse_event: InputEventMouseButton)
signal slot_hovered(slot_index: int)

# === COMPOSANTS ===
var item_icon: TextureRect  
var quantity_label: Label
var button: Button
var visual_manager: SlotVisualManager

# === DONNÉES ===
var slot_index: int = -1
var slot_data: Dictionary = {"is_empty": true}

func _ready():
	_initialize_components()

func _initialize_components():
	"""Initialise tous les composants du slot"""
	_find_ui_components()
	_setup_visual_manager()
	_setup_button()
	clear_slot()

func _find_ui_components():
	"""Trouve les composants UI existants"""
	item_icon = get_node_or_null("ItemIcon")
	quantity_label = get_node_or_null("QuantityLabel") 
	button = get_node_or_null("Button")

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
	"""Connecte les signaux du bouton"""
	if not button.gui_input.is_connected(_on_button_gui_input):
		button.gui_input.connect(_on_button_gui_input)
	if not button.mouse_entered.is_connected(_on_mouse_entered):
		button.mouse_entered.connect(_on_mouse_entered)
	if not button.mouse_exited.is_connected(_on_mouse_exited):
		button.mouse_exited.connect(_on_mouse_exited)

# === ÉVÉNEMENTS SOURIS ===

func _on_button_gui_input(event: InputEvent):
	"""Capture et émets les clics"""
	if event is InputEventMouseButton and not event.pressed:
		# Toujours émettre le clic, même sur slot vide
		slot_clicked.emit(slot_index, event as InputEventMouseButton)

func _on_mouse_entered():
	"""Gestion du survol"""
	if visual_manager:
		visual_manager.set_hover_state(true)
	slot_hovered.emit(slot_index)

func _on_mouse_exited():
	"""Fin du survol"""
	if visual_manager:
		visual_manager.set_hover_state(false)

# === API VISUELLE PUBLIQUE ===

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

# === GESTION DES DONNÉES ===

func set_slot_index(index: int):
	slot_index = index

func get_slot_index() -> int:
	return slot_index

func update_slot(slot_info: Dictionary):
	"""Met à jour l'affichage du slot - VERSION AVEC DEBUG"""
	var old_data = slot_data.duplicate()
	slot_data = slot_info
	
	# DEBUG: Vérifier les changements significatifs
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
	
	# NOUVEAU: Forcer une mise à jour visuelle immédiate
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
	"""Met à jour le label de quantité - VERSION CORRIGÉE"""
	if not quantity_label:
		return
	
	var qty = slot_info.get("quantity", 1)
	
	# CORRECTION CRUCIALE: Toujours afficher la quantité si > 1
	if qty > 1:
		quantity_label.text = str(qty)
		quantity_label.visible = true
		print("  📊 Quantité mise à jour: %d" % qty)
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
	"""NOUVEAU: Force un redraw immédiat de tous les composants"""
	await get_tree().process_frame
	
	if item_icon:
		item_icon.queue_redraw()
	if quantity_label:
		quantity_label.queue_redraw()
	
	# Forcer un recalcul de layout si nécessaire
	if get_parent():
		get_parent().queue_sort()

# === UTILITAIRES ===

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

# === DEBUG ===

func debug_visual_state():
	"""Debug de l'état visuel"""
	if visual_manager:
		visual_manager.debug_state()
	else:
		print("❌ Pas de visual_manager")

func debug_slot_content():
	"""NOUVEAU: Debug du contenu du slot"""
	print("🔍 Slot[%d] Debug:" % slot_index)
	print("   - Vide: %s" % slot_data.get("is_empty", true))
	print("   - Item: %s" % slot_data.get("item_name", "aucun"))
	print("   - Quantité: %d" % slot_data.get("quantity", 0))
	print("   - UI Icon visible: %s" % (item_icon.visible if item_icon else "N/A"))
	print("   - UI Label visible: %s" % (quantity_label.visible if quantity_label else "N/A"))
	print("   - UI Label text: '%s'" % (quantity_label.text if quantity_label else "N/A"))
