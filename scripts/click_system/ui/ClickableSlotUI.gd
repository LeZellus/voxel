# scripts/click_system/ui/ClickableSlotUI.gd
class_name ClickableSlotUI
extends Control

# === SIGNAUX POUR LE CLICK SYSTEM ===
signal slot_clicked(slot_index: int, mouse_event: InputEventMouseButton)
signal slot_hovered(slot_index: int)

# === COMPOSANTS UI ===
@onready var background: ColorRect = $Background
@onready var item_icon: TextureRect = $ItemIcon  
@onready var quantity_label: Label = $QuantityLabel
@onready var button: Button = $Button

# === DONNÉES DU SLOT ===
var slot_index: int = -1
var slot_data: Dictionary = {"is_empty": true}
var is_selected: bool = false

func _ready():
	setup_button()
	clear_slot()

func setup_button():
	"""Configure le bouton pour capturer tous les clics"""
	if not button:
		print("❌ Button manquant dans ClickableSlotUI")
		return
	
	# Le bouton doit capturer TOUS les clics
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	
	# Connecter le signal GUI input pour capturer les différents types de clics
	button.gui_input.connect(_on_button_gui_input)
	button.mouse_entered.connect(_on_mouse_entered)

func _on_button_gui_input(event: InputEvent):
	"""Capture tous les événements de souris sur le slot"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# Ne traiter que les clics (pas les press)
		if not mouse_event.pressed:
			print("🎯 Clic sur slot %d, bouton: %d" % [slot_index, mouse_event.button_index])
			slot_clicked.emit(slot_index, mouse_event)

func _on_mouse_entered():
	"""Émission du signal de hover"""
	slot_hovered.emit(slot_index)

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
	if not item_icon:
		return
	
	# Icône
	var icon_texture = slot_info.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		item_icon.visible = true
	else:
		# Fallback coloré pour les tests
		item_icon.texture = _create_fallback_icon()
		item_icon.visible = true
	
	# Quantité
	if quantity_label:
		var qty = slot_info.get("quantity", 1)
		quantity_label.text = str(qty)
		quantity_label.visible = qty > 1

func clear_slot():
	"""Vide l'affichage du slot"""
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
		
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
		
	slot_data = {"is_empty": true}

func _create_fallback_icon() -> ImageTexture:
	"""Crée une icône de fallback pour les tests"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE)  # Orange pour identifier les fallback
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# === ÉTATS VISUELS ===

func set_selected(selected: bool):
	"""Marque le slot comme sélectionné (pour click-and-click)"""
	is_selected = selected
	
	if background:
		if selected:
			background.color = Color.YELLOW
		else:
			background.color = Color(0.09, 0.125, 0.22, 0.8)  # Couleur normale

func set_waiting_for_target(waiting: bool):
	"""Marque visuellement que ce slot attend une cible"""
	if background:
		if waiting:
			background.color = Color.CYAN
		else:
			background.color = Color(0.09, 0.125, 0.22, 0.8)

# === UTILITAIRES ===

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func get_slot_data() -> Dictionary:
	return slot_data.duplicate()

# === DEBUG ===

func _to_string() -> String:
	return "ClickableSlotUI[%d]: %s" % [slot_index, "empty" if is_empty() else get_item_name()]
