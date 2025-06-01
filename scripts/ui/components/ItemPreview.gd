# scripts/ui/components/ItemPreview.gd - VERSION FINALE
class_name ItemPreview
extends Control

var is_active: bool = false
var item_icon: TextureRect
var quantity_label: Label
var bg_rect: ColorRect
var is_setup_complete: bool = false

func _ready():
	print("🔧 ItemPreview FINAL: _ready() appelé")
	call_deferred("_create_final_ui")

func _create_final_ui():
	"""Crée une UI finale avec icônes réelles"""
	print("🔧 Création UI finale...")
	
	size = Vector2(64, 64)
	custom_minimum_size = size
	
	# Background avec style moderne
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.size = size
	bg_rect.color = Color(0.1, 0.1, 0.15, 0.95)  # Bleu foncé semi-transparent
	bg_rect.z_index = -1
	add_child(bg_rect)
	
	# Bordure subtile
	var border = ColorRect.new()
	border.name = "Border"
	border.size = size
	border.color = Color.TRANSPARENT
	# Simuler une bordure avec modulate
	border.modulate = Color(0.6, 0.6, 0.7, 0.8)
	add_child(border)
	
	# Icône de l'item (plus grande)
	item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.size = Vector2(56, 56)
	item_icon.position = Vector2(4, 4)
	item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(item_icon)
	
	# Label de quantité stylé
	quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.size = Vector2(24, 20)
	quantity_label.position = Vector2(36, 40)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	quantity_label.add_theme_constant_override("shadow_offset_x", 2)
	quantity_label.add_theme_constant_override("shadow_offset_y", 2)
	quantity_label.add_theme_font_size_override("font_size", 14)
	add_child(quantity_label)
	
	# État initial
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 9999  # Au-dessus de tout
	
	is_setup_complete = true
	print("✅ UI finale créée - Taille: %s" % size)

func show_item(item_data: Dictionary):
	"""Version finale d'affichage avec icônes réelles"""
	print("📦 FINAL show_item appelé avec: %s" % item_data.get("item_name", "Inconnu"))
	
	# Vérifier que l'UI est créée
	if not is_setup_complete:
		print("⚠️ UI pas encore créée, création forcée...")
		_create_final_ui()
		await get_tree().process_frame
	
	# Vérifier les composants
	if not item_icon or not is_instance_valid(item_icon):
		print("❌ item_icon invalide")
		return
	
	if not quantity_label or not is_instance_valid(quantity_label):
		print("❌ quantity_label invalide")
		return
	
	# Mettre à jour l'icône RÉELLE
	var icon_texture = item_data.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		item_icon.visible = true
		print("✅ Icône réelle appliquée")
	else:
		# Fallback : créer une icône colorée selon le type d'item
		var fallback_color = _get_fallback_color(item_data.get("item_type", 0))
		item_icon.texture = _create_fallback_icon(fallback_color)
		item_icon.visible = true
		print("⚠️ Icône fallback utilisée: %s" % fallback_color)
	
	# Mettre à jour la quantité
	var qty = item_data.get("quantity", 1)
	if qty > 1:
		quantity_label.text = str(qty)
		quantity_label.visible = true
		print("✅ Quantité affichée: %d" % qty)
	else:
		quantity_label.visible = false
	
	is_active = true
	visible = true
	print("✅ Preview finale affichée")

func _get_fallback_color(item_type: int) -> Color:
	"""Couleur de fallback selon le type d'item"""
	match item_type:
		0: return Color.RED      # CONSUMABLE
		1: return Color.SILVER   # TOOL
		2: return Color(0.6, 0.3, 0.1)  # RESOURCE (brun)
		3: return Color.GOLD     # EQUIPMENT
		_: return Color.GRAY

func _create_fallback_icon(color: Color) -> ImageTexture:
	"""Crée une icône de fallback colorée"""
	var image = Image.create(48, 48, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func hide_item():
	"""Cache la preview"""
	print("📦 FINAL hide_item appelé")
	is_active = false
	visible = false

func update_position(mouse_pos: Vector2):
	"""Met à jour la position selon la souris"""
	if not is_active:
		return
	
	# Offset pour éviter que l'item cache la souris
	var offset = Vector2(15, -15)
	position = mouse_pos + offset
	
	# S'assurer que la preview reste dans l'écran
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 0, viewport_size.x - size.x)
	position.y = clamp(position.y, 0, viewport_size.y - size.y)

func _input(event):
	"""Suit la souris en permanence"""
	if event is InputEventMouseMotion and is_active:
		update_position(event.global_position)

# Méthode de debug
func debug_state():
	"""Affiche l'état interne pour debug"""
	print("\n🔍 ÉTAT ITEMPREVIEW FINAL:")
	print("   - is_setup_complete: %s" % is_setup_complete)
	print("   - item_icon existe: %s" % (item_icon != null))
	print("   - quantity_label existe: %s" % (quantity_label != null))
	print("   - bg_rect existe: %s" % (bg_rect != null))
	print("   - is_active: %s" % is_active)
	print("   - visible: %s" % visible)
	print("   - size: %s" % size)
	print("   - children count: %d" % get_child_count())
