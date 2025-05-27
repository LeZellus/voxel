# InventorySlot2D.gd - Slot d'inventaire avec icône 2D
# À sauvegarder dans : res://scripts/ui/InventorySlot2D.gd
extends Control

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel

var item_data: Item

func _ready():
	# Configure l'icône
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.anchors_preset = Control.PRESET_FULL_RECT
	
	# Configure le label de quantité
	quantity_label.text = ""
	quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	quantity_label.add_theme_color_override("font_color", Color.WHITE)

func set_item(item: Item, quantity: int = 1):
	item_data = item
	
	if item == null or quantity <= 0:
		# Slot vide
		icon_texture.texture = null
		quantity_label.text = ""
		return
	
	# Applique l'icône 2D
	icon_texture.texture = item.icon  # Supposant que Item a une propriété 'icon'
	
	# Affiche la quantité si > 1
	if quantity > 1:
		quantity_label.text = str(quantity)
	else:
		quantity_label.text = ""

func clear_slot():
	set_item(null, 0)
