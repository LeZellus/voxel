extends Node
class_name GameManager

var normal_cursor: ImageTexture
var click_cursor: ImageTexture

func _ready():
	
	var service_locator = ServiceLocator.new()
	var events = Events.new()
	add_child(service_locator)
	add_child(events)
	
	# Charger les deux textures
	var tex1 = load("res://assets/icons/iso_mouse2.png")
	var tex2 = load("res://assets/icons/iso_mouse.png")
	
	if tex1 == null:
		print("ERREUR: Fichier iso_mouse2.png introuvable!")
		return
	
	if tex2 == null:
		print("ERREUR: Fichier iso_mouse2_click.png introuvable!")
		print("Créer le fichier ou changer le nom dans le code")
		return
	
	normal_cursor = create_cursor(tex1)
	click_cursor = create_cursor(tex2)
	
	var audio_system = get_node("../AudioSystem")  # Ou le chemin correct
	ServiceLocator.register("audio", audio_system)
	
	# Définir le curseur normal au démarrage
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
				print("🧪 Test ServiceLocator: %s" % ServiceLocator.instance)
				print("🧪 Test Events: %s" % Events.instance)
			else:
				print("ERREUR: click_cursor est null!")
		else:
			if normal_cursor:
				Input.set_custom_mouse_cursor(normal_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
			else:
				print("ERREUR: normal_cursor est null!")
