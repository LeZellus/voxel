# scripts/ui/inventory/ClickableSlotUI.gd - VERSION NETTOYÉE
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
	"""Configure le gestionnaire visuel"""
	visual_manager = SlotVisualManager.new(self)
	visual_manager.create_overlays()

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
		slot_clicked.emit(slot_index, event as InputEventMouseButton)

func _on_mouse_entered():
	"""Gestion du survol"""
	visual_manager.set_hover_state(true)
	slot_hovered.emit(slot_index)

func _on_mouse_exited():
	"""Fin du survol"""
	visual_manager.set_hover_state(false)

# === API VISUELLE ===

func highlight_as_selected():
	"""Active la sélection visuelle"""
	visual_manager.set_selected_state(true)

func remove_selection_highlight():
	"""Désactive la sélection visuelle"""
	visual_manager.set_selected_state(false)
	
func show_error_feedback():
	"""Affiche le feedback d'erreur (action refusée)"""
	visual_manager.show_error_feedback()

# === GESTION DES DONNÉES ===

func set_slot_index(index: int):
	slot_index = index

func get_slot_index() -> int:
	return slot_index

func update_slot(slot_info: Dictionary):
	"""Met à jour l'affichage du slot"""
	slot_data = slot_info
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		_display_item(slot_info)

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
	quantity_label.text = str(qty)
	quantity_label.visible = qty > 1

func clear_slot():
	"""Vide complètement le slot"""
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
		
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
		
	slot_data = {"is_empty": true}

# === UTILITAIRES ===

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func get_slot_data() -> Dictionary:
	return slot_data.duplicate()
