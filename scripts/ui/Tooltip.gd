extends Control

@onready var item_name: Label = $Background/VBoxContainer/ItemName
@onready var item_description: Label = $Background/VBoxContainer/ItemDescription
@onready var background: Panel = $Background

func _ready():
	# Configure le style de base
	modulate.a = 0.0
	
	# Configure le fond noir
	setup_background_style()
	
	# Configure les styles de texte
	setup_text_styles()
	
	# Animation d'apparition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func setup_background_style():
	# Crée un fond noir avec bordure
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.0, 0.0, 0.0, 0.9)  # Noir semi-transparent
	
	# Ajoute du padding
	style_box.content_margin_left = 80
	style_box.content_margin_right = 80
	style_box.content_margin_top = 60
	style_box.content_margin_bottom = 60
	
	background.add_theme_stylebox_override("panel", style_box)
	background.custom_minimum_size = Vector2(100, 50)  # Taille minimale
	background.size = Vector2(200, 100)  # Taille de base
	
	# Forcez le VBoxContainer à respecter les marges
	var vbox = $Background/VBoxContainer
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 4
	vbox.offset_right = -4
	vbox.offset_top = 4
	vbox.offset_bottom = -4

func setup_text_styles():
	# Style pour le nom (plus gros)
	item_name.add_theme_font_size_override("font_size", 20)
	
	# Style pour la description (taille normale)
	item_description.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))  # Blanc cassé

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
	adjust_size()

func adjust_size():
	# Ajuste la taille de la tooltip selon le contenu
	background.size = Vector2.ZERO
	size = Vector2.ZERO
