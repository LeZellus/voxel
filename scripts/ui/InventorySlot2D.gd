# InventorySlot2D.gd - Slot d'inventaire avec fond et tooltip
extends Control

@onready var icon_texture: TextureRect = $IconTexture
@onready var quantity_label: Label = $QuantityLabel

var item_data: Item
var quantity: int = 0
var tooltip_manager: Node

func _ready():
	quantity_label.text = ""
	
func set_item(item: Item, qty: int = 1):
	item_data = item
	quantity = qty
	
	if item == null or qty <= 0:
		icon_texture.texture = null
		quantity_label.text = ""
		return
	
	icon_texture.texture = item.icon
	
	if qty > 1:
		quantity_label.text = str(qty)
	else:
		quantity_label.text = ""

func clear_slot():
	set_item(null, 0)
