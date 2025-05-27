extends Node

var normal_cursor: ImageTexture
var click_cursor: ImageTexture

func _ready():
	print("=== CHARGEMENT DES CURSEURS ===")
	
	# Charger les deux textures
	var tex1 = load("res://assets/icons/iso_mouse2.png")
	var tex2 = load("res://assets/icons/iso_mouse.png")
	
	print("Texture normale chargée: ", tex1 != null)
	print("Texture clic chargée: ", tex2 != null)
	
	if tex1 == null:
		print("ERREUR: Fichier iso_mouse2.png introuvable!")
		return
	
	if tex2 == null:
		print("ERREUR: Fichier iso_mouse2_click.png introuvable!")
		print("Créer le fichier ou changer le nom dans le code")
		return
	
	normal_cursor = create_cursor(tex1)
	click_cursor = create_cursor(tex2)
	
	print("Curseur normal créé: ", normal_cursor != null)
	print("Curseur clic créé: ", click_cursor != null)
	
	# Définir le curseur normal au démarrage
	Input.set_custom_mouse_cursor(normal_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
	print("Curseur normal appliqué")

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
		print("=== ÉVÉNEMENT SOURIS ===")
		print("Bouton pressé: ", event.pressed)
		
		if event.pressed:
			print("CLIC DÉTECTÉ - Changement vers curseur de clic")
			if click_cursor:
				Input.set_custom_mouse_cursor(click_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
				print("Curseur de clic appliqué")
			else:
				print("ERREUR: click_cursor est null!")
		else:
			print("RELÂCHEMENT DÉTECTÉ - Retour curseur normal")
			if normal_cursor:
				Input.set_custom_mouse_cursor(normal_cursor, Input.CURSOR_ARROW, Vector2(16, 0))
				print("Curseur normal restauré")
			else:
				print("ERREUR: normal_cursor est null!")
