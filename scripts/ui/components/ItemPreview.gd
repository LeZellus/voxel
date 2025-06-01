# scripts/ui/components/ItemPreview.gd - VERSION NETTOYÉE
class_name ItemPreview
extends Control

var is_active: bool = false
var item_icon: TextureRect
var quantity_label: Label

func _ready():
	"""Configuration initiale de la preview"""
	print("🔧 ItemPreview._ready() appelé")
	visible = false
	is_active = false
	_find_components()
	
	# Si les composants n'existent pas, les créer
	if not item_icon or not quantity_label:
		print("⚠️ Composants manquants, création automatique...")
		_create_missing_components()

func _find_components():
	"""Trouve les composants UI de la scène"""
	print("🔍 Recherche des composants dans ItemPreview...")
	
	# Debug : afficher tous les enfants
	print("📋 Enfants disponibles:")
	for child in get_children():
		print("   - %s (%s)" % [child.name, child.get_class()])
	
	# Recherche flexible des composants
	item_icon = get_node_or_null("ItemIcon")
	if not item_icon:
		# Recherche alternative par type
		for child in get_children():
			if child is TextureRect:
				item_icon = child
				print("✅ ItemIcon trouvé par type: %s" % child.name)
				break
	else:
		print("✅ ItemIcon trouvé par nom")
	
	quantity_label = get_node_or_null("QuantityLabel")
	if not quantity_label:
		# Recherche alternative par type
		for child in get_children():
			if child is Label:
				quantity_label = child
				print("✅ QuantityLabel trouvé par type: %s" % child.name)
				break
	else:
		print("✅ QuantityLabel trouvé par nom")
	
	# S'assurer que le label est caché par défaut
	if quantity_label:
		quantity_label.visible = false
		quantity_label.text = ""
		print("✅ QuantityLabel configuré")
	
	# Résultat final
	print("📋 Résultat recherche:")
	print("   - ItemIcon: %s" % ("✅" if item_icon else "❌"))
	print("   - QuantityLabel: %s" % ("✅" if quantity_label else "❌"))

func show_item(item_data: Dictionary):
	"""Affiche un item dans la preview"""
	print("📦 ItemPreview.show_item() appelé avec: %s" % item_data.get("item_name", "Inconnu"))
	
	if not _validate_components():
		print("❌ Composants invalides")
		return
	
	_update_icon(item_data)
	_update_quantity(item_data)
	
	is_active = true
	visible = true
	
	# Position à la souris
	position = get_viewport().get_mouse_position()
	print("✅ Preview affichée à: %s (visible: %s)" % [position, visible])

func hide_item():
	"""Cache la preview"""
	is_active = false
	visible = false

func update_position(mouse_pos: Vector2):
	"""Met à jour la position selon la souris"""
	if not is_active:
		return
	
	position = mouse_pos
	_clamp_to_screen()

func _update_icon(item_data: Dictionary):
	"""Met à jour l'icône"""
	var icon_texture = item_data.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
	else:
		item_icon.texture = null

func _update_quantity(item_data: Dictionary):
	"""Met à jour la quantité"""
	var qty = item_data.get("quantity", 1)
	if qty > 1:
		quantity_label.text = str(qty)
		quantity_label.visible = true
	else:
		quantity_label.text = ""
		quantity_label.visible = false

func _validate_components() -> bool:
	"""Vérifie que les composants sont disponibles"""
	if not item_icon:
		print("❌ item_icon introuvable")
		return false
	print("✅ Composants validés")
	return true

func _create_missing_components():
	"""Crée les composants manquants"""
	if not item_icon:
		print("🔧 Création de ItemIcon...")
		item_icon = TextureRect.new()
		item_icon.name = "ItemIcon"
		item_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.anchors_preset = Control.PRESET_FULL_RECT
		add_child(item_icon)
	
	if not quantity_label:
		print("🔧 Création de QuantityLabel...")
		quantity_label = Label.new()
		quantity_label.name = "QuantityLabel"
		quantity_label.text = ""
		quantity_label.visible = false
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.anchors_preset = Control.PRESET_FULL_RECT
		add_child(quantity_label)
	
	# Configuration de base
	custom_minimum_size = Vector2(48, 48)
	print("✅ Composants créés automatiquement")

func _clamp_to_screen():
	"""Maintient la preview dans l'écran"""
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 0, viewport_size.x - size.x)
	position.y = clamp(position.y, 0, viewport_size.y - size.y)

func _input(event):
	"""Suit la souris automatiquement"""
	if event is InputEventMouseMotion and is_active:
		update_position(event.global_position)
