# scripts/ui/inventory/ClickableSlotUI.gd - VERSION PROPRE FONCTIONNELLE
class_name ClickableSlotUI
extends Control

# === SIGNAUX ===
signal slot_clicked(slot_index: int, mouse_event: InputEventMouseButton)
signal slot_hovered(slot_index: int)

# === COMPOSANTS UI ===
var background: ColorRect
var item_icon: TextureRect  
var quantity_label: Label
var button: Button

# === OVERLAYS VISUELS ===
var hover_overlay: ColorRect
var selected_overlay: ColorRect

# === DONNÉES DU SLOT ===
var slot_index: int = -1
var slot_data: Dictionary = {"is_empty": true}

# === ÉTATS VISUELS ===
var is_hovered: bool = false
var is_selected: bool = false

func _ready():
	_find_components()
	_create_visual_overlays()
	setup_button()
	clear_slot()

func _find_components():
	"""Trouve les composants existants"""
	background = get_node_or_null("ColorRect")
	item_icon = get_node_or_null("ItemIcon")
	quantity_label = get_node_or_null("QuantityLabel") 
	button = get_node_or_null("Button")

func _create_visual_overlays():
	"""Crée les overlays hover et sélection - VERSION FINALE"""
	
	await get_tree().process_frame
	
	# Hover overlay - BLANC LÉGER au survol
	hover_overlay = ColorRect.new()
	hover_overlay.name = "HoverOverlay"
	hover_overlay.color = Color(1, 1, 1, 0.15)  # Blanc léger
	hover_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_overlay.position = Vector2.ZERO
	hover_overlay.size = self.size
	hover_overlay.visible = false  # Caché par défaut
	hover_overlay.z_index = 50
	add_child(hover_overlay)
	
	# Selected overlay - BLEU pour la sélection
	selected_overlay = ColorRect.new()
	selected_overlay.name = "SelectedOverlay"
	selected_overlay.color = Color(0.3, 0.7, 1.0, 0.4)  # Bleu semi-transparent
	selected_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_overlay.position = Vector2.ZERO
	selected_overlay.size = self.size
	selected_overlay.visible = false  # Caché par défaut
	selected_overlay.z_index = 51  # Au-dessus du hover
	add_child(selected_overlay)

func setup_button():
	"""Configure le bouton sans effets visuels"""
	if not button:
		button = get_node_or_null("Button")
	
	if not button:
		return
	
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	
	# Connecter les signaux
	if not button.gui_input.is_connected(_on_button_gui_input):
		button.gui_input.connect(_on_button_gui_input)
	if not button.mouse_entered.is_connected(_on_mouse_entered):
		button.mouse_entered.connect(_on_mouse_entered)
	if not button.mouse_exited.is_connected(_on_mouse_exited):
		button.mouse_exited.connect(_on_mouse_exited)

# === ÉVÉNEMENTS ===

func _on_button_gui_input(event: InputEvent):
	"""Capture les clics"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if not mouse_event.pressed:
			slot_clicked.emit(slot_index, mouse_event)

func _on_mouse_entered():
	"""Hover activé"""
	set_hover_state(true)
	slot_hovered.emit(slot_index)

func _on_mouse_exited():
	"""Hover désactivé"""
	set_hover_state(false)

# === GESTION ÉTATS VISUELS ===

func set_hover_state(hovered: bool):
	"""Active/désactive le hover"""
	if is_hovered == hovered:
		return
	is_hovered = hovered
	_update_visual_state()

func set_selected_state(selected: bool):
	"""Active/désactive la sélection"""
	if is_selected == selected:
		return
	is_selected = selected
	_update_visual_state()

func _update_visual_state():
	"""Met à jour l'affichage"""
	if not hover_overlay or not selected_overlay:
		return
	
	# Hover seulement si pas sélectionné
	hover_overlay.visible = is_hovered and not is_selected
	
	# Sélection prioritaire
	selected_overlay.visible = is_selected

# === API PUBLIQUE ===

func highlight_as_selected():
	"""Marque comme sélectionné"""
	set_selected_state(true)

func remove_selection_highlight():
	"""Retire la sélection"""
	set_selected_state(false)

# === GESTION DONNÉES (inchangé) ===

func set_slot_index(index: int):
	slot_index = index

func get_slot_index() -> int:
	return slot_index

func update_slot(slot_info: Dictionary):
	slot_data = slot_info
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		_display_item(slot_info)

func _display_item(slot_info: Dictionary):
	if not item_icon:
		item_icon = get_node_or_null("ItemIcon")
	
	if not item_icon:
		return
	
	var icon_texture = slot_info.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		item_icon.visible = true
	
	if not quantity_label:
		quantity_label = get_node_or_null("QuantityLabel")
	
	if quantity_label:
		var qty = slot_info.get("quantity", 1)
		quantity_label.text = str(qty)
		quantity_label.visible = qty > 1

func clear_slot():
	if not item_icon:
		item_icon = get_node_or_null("ItemIcon")
	if not quantity_label:
		quantity_label = get_node_or_null("QuantityLabel")
	
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
		
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
		
	slot_data = {"is_empty": true}

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func get_slot_data() -> Dictionary:
	return slot_data.duplicate()
