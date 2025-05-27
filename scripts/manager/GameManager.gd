extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var cursor_texture = load("res://assets/icons/iso_mouse2.png")
	
	# Vérifiez que la texture est chargée
	if cursor_texture == null:
		print("Erreur : texture non trouvée")
		return
	
	# Méthode corrigée pour obtenir l'image
	var image = cursor_texture.get_image()
	if image == null:
		print("Erreur : impossible d'obtenir l'image")
		return
	
	# Agrandissement
	image.resize(32, 32, Image.INTERPOLATE_NEAREST)
	
	var new_texture = ImageTexture.new()
	new_texture.set_image(image)  # Utilisez set_image au lieu de create_from_image
	
	Input.set_custom_mouse_cursor(new_texture, Input.CURSOR_ARROW, Vector2(16, 0))
