# scripts/manager/GameManager.gd - AVEC PREVIEWMANAGER INTÉGRÉ
extends Node
class_name GameManager

var normal_cursor: ImageTexture
var click_cursor: ImageTexture

func _ready():
	_setup_core_systems()
	_setup_cursors()

func _setup_core_systems():
	"""Initialise les systèmes centraux"""
	# ServiceLocator et Events
	var service_locator = ServiceLocator.new()
	var events = Events.new()
	add_child(service_locator)
	add_child(events)
	
	# PreviewManager (nouveau)
	var preview_manager = PreviewManager.new()
	add_child(preview_manager)
	ServiceLocator.register("preview", preview_manager)
	
	# AudioSystem
	var audio_system = get_node_or_null("../AudioSystem")
	if audio_system:
		ServiceLocator.register("audio", audio_system)
	else:
		print("❌ AudioSystem introuvable dans la scène")

func _setup_cursors():
	"""Configure les curseurs"""
	var tex1 = load("res://assets/icons/iso_mouse2.png")
	var tex2 = load("res://assets/icons/iso_mouse.png")
	
	if tex1 == null or tex2 == null:
		print("❌ Fichiers de curseur introuvables!")
		return
	
	normal_cursor = create_cursor(tex1)
	click_cursor = create_cursor(tex2)
	
	Input.set_custom_mouse_cursor(normal_cursor, Input.CURSOR_ARROW, Vector2(16, 0))

func create_cursor(texture):
	if texture == null:
		return null
		
	var image = texture.get_image()
	if image == null:
		print("Impossible d'obtenir l'image")
		return null
		
	image.resize(32, 32, Image.INTERPOLATE_NEAREST)
	var new_texture = ImageTexture.new()
	new_texture.set_image(image)
	return new_texture

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if click_cursor:
				Input.set_custom_mouse_cursor(click_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
		else:
			if normal_cursor:
				Input.set_custom_mouse_cursor(normal_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
