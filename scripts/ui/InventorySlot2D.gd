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
	
	# Configure le label de quantité - SOLUTION ROBUSTE
	quantity_label.text = ""
	# Position absolue depuis le coin bas-droit
	quantity_label.position = Vector2(0, 0)  # Sera ajusté dynamiquement
	quantity_label.anchor_left = 1.0
	quantity_label.anchor_right = 1.0 
	quantity_label.anchor_top = 1.0
	quantity_label.anchor_bottom = 1.0
	# Le label se dimensionne automatiquement selon son contenu
	quantity_label.custom_minimum_size = Vector2.ZERO
	quantity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	quantity_label.clip_contents = false
	
	# Style du texte
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_font_size_override("font_size", 12)
	
	# Ajoute une ombre pour améliorer la lisibilité
	quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	quantity_label.add_theme_constant_override("shadow_offset_x", 1)
	quantity_label.add_theme_constant_override("shadow_offset_y", 1)
	
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
		var qty_text = str(qty)
		quantity_label.text = qty_text
		
		# Position dynamique selon la taille du texte
		_position_quantity_label(qty_text)
	else:
		quantity_label.text = ""

func _position_quantity_label(text: String):
	# Calcule la taille exacte du texte
	var font = quantity_label.get_theme_default_font()
	var font_size = 12  # Taille définie plus haut
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Position depuis le coin bas-droit avec marges de 4px
	var x_pos = size.x - text_size.x - 4
	var y_pos = size.y - text_size.y - 4
	
	quantity_label.position = Vector2(x_pos, y_pos)
	quantity_label.size = text_size

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
