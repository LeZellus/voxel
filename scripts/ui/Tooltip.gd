extends Control

@onready var item_name: Label = $Background/VBoxContainer/ItemName
@onready var item_description: Label = $Background/VBoxContainer/ItemDescription
@onready var background: Control = $Background

func _ready():
	# Configure le style de base
	modulate.a = 0.0
	
	# Animation d'apparition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func setup_tooltip(item: Item):
	# Configure la tooltip avec les données de l'item
	if not item:
		print("Tooltip: item est null")
		return
	
	# Configure le texte
	item_name.text = item.name if "name" in item else "Item"
	item_description.text = item.description if "description" in item else ""
	
	# Ajuste la taille si nécessaire
	await get_tree().process_frame
	_adjust_size()

func _adjust_size():
	# Ajuste la taille de la tooltip selon le contenu
	background.size = Vector2.ZERO
	size = Vector2.ZERO
