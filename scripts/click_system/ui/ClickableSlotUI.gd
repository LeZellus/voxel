# scripts/click_system/ui/ClickableSlotUI.gd - VERSION CORRIGÉE
class_name ClickableSlotUI
extends Control

# === SIGNAUX POUR LE CLICK SYSTEM ===
signal slot_clicked(slot_index: int, mouse_event: InputEventMouseButton)
signal slot_hovered(slot_index: int)

# === COMPOSANTS UI (références sécurisées) ===
var background: ColorRect
var item_icon: TextureRect  
var quantity_label: Label
var button: Button

# === DONNÉES DU SLOT ===
var slot_index: int = -1
var slot_data: Dictionary = {"is_empty": true}
var is_selected: bool = false

func _ready():
	# Rechercher les composants de manière sécurisée
	_find_components()
	setup_button()
	clear_slot()

func _find_components():
	"""Trouve les composants même s'ils sont créés dynamiquement"""
	# Utiliser des références directes plutôt que @onready
	background = get_node_or_null("ColorRect")
	item_icon = get_node_or_null("ItemIcon")
	quantity_label = get_node_or_null("QuantityLabel") 
	button = get_node_or_null("Button")
	
	print("🔍 Slot %d - Composants trouvés: bg=%s, icon=%s, label=%s, btn=%s" % [
		slot_index,
		str(background != null),
		str(item_icon != null), 
		str(quantity_label != null),
		str(button != null)
	])

func setup_button():
	"""Configure le bouton pour capturer tous les clics"""
	# Rechercher le bouton s'il n'est pas encore trouvé
	if not button:
		button = get_node_or_null("Button")
	
	if not button:
		print("❌ Button manquant dans ClickableSlotUI slot %d" % slot_index)
		return
	
	# Configuration du bouton
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	
	# Connecter les signaux (éviter les doubles connexions)
	if not button.gui_input.is_connected(_on_button_gui_input):
		button.gui_input.connect(_on_button_gui_input)
	if not button.mouse_entered.is_connected(_on_mouse_entered):
		button.mouse_entered.connect(_on_mouse_entered)
	
	print("✅ Button configuré pour slot %d" % slot_index)

func _on_button_gui_input(event: InputEvent):
	"""Capture tous les événements de souris sur le slot"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		# Ne traiter que les releases (pas les press)
		if not mouse_event.pressed:
			print("🎯 Clic détecté slot %d, bouton: %d" % [slot_index, mouse_event.button_index])
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
	
	print("🔄 Update slot %d avec: %s" % [slot_index, slot_info])
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		_display_item(slot_info)

func _display_item(slot_info: Dictionary):
	"""Affiche un item dans le slot"""
	# S'assurer qu'on a l'icône
	if not item_icon:
		item_icon = get_node_or_null("ItemIcon")
	
	if not item_icon:
		print("❌ ItemIcon introuvable pour slot %d" % slot_index)
		return
	
	# Icône
	var icon_texture = slot_info.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		item_icon.visible = true
		print("✅ Icône appliquée à slot %d" % slot_index)
	else:
		# Fallback coloré pour debug
		item_icon.texture = _create_fallback_icon()
		item_icon.visible = true
		print("⚠️ Fallback icon pour slot %d" % slot_index)
	
	# Quantité
	if not quantity_label:
		quantity_label = get_node_or_null("QuantityLabel")
	
	if quantity_label:
		var qty = slot_info.get("quantity", 1)
		quantity_label.text = str(qty)
		quantity_label.visible = qty > 1
		print("📊 Quantité %d affichée pour slot %d" % [qty, slot_index])

func clear_slot():
	"""Vide l'affichage du slot"""
	# Rechercher les composants si nécessaire
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

func _create_fallback_icon() -> ImageTexture:
	"""Crée une icône de fallback pour debug"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE)  # Orange pour identifier les fallback
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# === ÉTATS VISUELS ===

func set_selected(selected: bool):
	"""Marque le slot comme sélectionné"""
	is_selected = selected
	
	if not background:
		background = get_node_or_null("ColorRect")
	
	if background:
		if selected:
			background.color = Color.YELLOW
		else:
			background.color = Color(0.09, 0.125, 0.22, 0.8)

func set_waiting_for_target(waiting: bool):
	"""Marque visuellement que ce slot attend une cible"""
	if not background:
		background = get_node_or_null("ColorRect")
	
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

func debug_components():
	"""Debug des composants"""
	print("🔍 Slot %d composants:" % slot_index)
	print("   - background: %s" % str(background))
	print("   - item_icon: %s" % str(item_icon))
	print("   - quantity_label: %s" % str(quantity_label))
	print("   - button: %s" % str(button))
