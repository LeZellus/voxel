# scripts/ui/components/ItemPreview.gd - VERSION CORRIGÉE
class_name ItemPreview
extends Control

var is_active: bool = false
var item_icon: TextureRect
var quantity_label: Label
var is_setup_complete: bool = false

func _ready():
	print("🔧 ItemPreview: _ready() appelé")
	# Ne pas créer d'UI - c'est géré par la scène
	is_setup_complete = true

func show_item(item_data: Dictionary):
	"""Affiche l'item sans créer de style - utilise la scène existante"""
	print("📦 show_item appelé avec: %s" % item_data.get("item_name", "Inconnu"))
	
	# Trouver les composants de la scène
	if not item_icon:
		item_icon = get_node_or_null("ItemIcon")
	if not quantity_label:
		quantity_label = get_node_or_null("QuantityLabel")
	
	if not item_icon:
		print("❌ ItemIcon introuvable dans la scène")
		return
	
	# Mettre à jour l'icône
	var icon_texture = item_data.get("icon")
	if icon_texture and icon_texture is Texture2D:
		item_icon.texture = icon_texture
		print("✅ Icône appliquée")
	else:
		item_icon.texture = null
		print("⚠️ Pas d'icône disponible")
	
	# Mettre à jour la quantité
	if quantity_label:
		var qty = item_data.get("quantity", 1)
		if qty > 1:
			quantity_label.text = str(qty)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	
	is_active = true
	visible = true
	
	# Position initiale à la souris SANS offset
	var mouse_pos = get_viewport().get_mouse_position()
	position = mouse_pos
	
	print("✅ Preview affichée à: %s" % position)

func hide_item():
	"""Cache la preview"""
	print("📦 hide_item appelé")
	is_active = false
	visible = false

func update_position(mouse_pos: Vector2):
	"""Met à jour la position - SANS décalage pour qu'elle reste fixe par rapport à la souris"""
	if not is_active:
		return
	
	# Position exacte de la souris, sans offset
	position = mouse_pos
	
	# S'assurer que la preview reste dans l'écran
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = clamp(position.x, 0, viewport_size.x - size.x)
	position.y = clamp(position.y, 0, viewport_size.y - size.y)

func _input(event):
	"""Suit la souris en permanence"""
	if event is InputEventMouseMotion and is_active:
		update_position(event.global_position)
