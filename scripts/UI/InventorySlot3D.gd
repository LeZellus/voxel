# InventorySlot2D.gd - Slot d'inventaire avec fond et tooltip
extends Control

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel

var item_data: Item
var quantity: int = 0
var tooltip_manager: Node

func _ready():
	# Configure le fond de la case
	setup_background()
	
	# Configure l'icône
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_texture.anchors_preset = Control.PRESET_FULL_RECT
	
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_texture.size = Vector2(48, 48)  # Plus petit que les 64x64 de la case
	icon_texture.position = Vector2(8, 8)  # Centré avec marge
	
	# Configure le label de quantité
	quantity_label.text = ""
	quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Connecte les signaux pour la tooltip
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Récupère le TooltipManager
	tooltip_manager = get_node("/root/TooltipManager")

func setup_background():
	# Crée un fond sombre avec bordure
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.062, 0.078, 0.122, 0.9)  # Gris foncé semi-transparent
	
	add_theme_stylebox_override("panel", style_box)

func set_item(item: Item, qty: int = 1):
	item_data = item
	quantity = qty
	
	if item == null or qty <= 0:
		# Slot vide - fond normal
		update_background_state(false)
		icon_texture.texture = null
		quantity_label.text = ""
		return
	
	# Slot occupé - fond légèrement différent
	update_background_state(true)
	icon_texture.texture = item.icon
	
	if qty > 1:
		quantity_label.text = str(qty)
	else:
		quantity_label.text = ""

func update_background_state(has_item: bool):
	var style_box = StyleBoxFlat.new()
	
	if has_item:
		# Fond plus clair pour les cases occupées
		style_box.bg_color = Color(0.082, 0.114, 0.157, 0.9)
	else:
		# Fond normal pour les cases vides
		style_box.bg_color = Color(0.062, 0.078, 0.122, 0.9)
	
	add_theme_stylebox_override("panel", style_box)

func clear_slot():
	set_item(null, 0)

func _on_mouse_entered():
	if item_data and tooltip_manager:
		var tooltip_pos = global_position + Vector2(size.x + 10, 0)
		tooltip_manager.show_tooltip(item_data, tooltip_pos)

func _on_mouse_exited():
	if tooltip_manager:
		tooltip_manager.hide_tooltip()
