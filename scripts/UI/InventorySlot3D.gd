# InventorySlot3D.gd - Slot d'inventaire avec objet 3D
# À sauvegarder dans : res://scripts/ui/InventorySlot3D.gd
extends Control

@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D
@onready var item_node: MeshInstance3D = $SubViewport/ItemDisplay
@onready var light: DirectionalLight3D = $SubViewport/DirectionalLight3D
@onready var quantity_label: Label = $QuantityLabel

var item_data: Item
var rotation_speed: float = 45.0  # Degrés par seconde

func _ready():
	# Configure le viewport pour qu'il soit transparent
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Configure la caméra
	camera.position = Vector3(0, 0, 2)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Configure l'éclairage
	light.position = Vector3(1, 1, 1)
	light.rotation_degrees = Vector3(-30, 45, 0)
	
	# Configure le label de quantité
	quantity_label.text = ""
	quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	quantity_label.add_theme_color_override("font_color", Color.WHITE)

func _process(delta):
	# Fait tourner l'objet
	if item_node.mesh != null:
		item_node.rotation.y += deg_to_rad(rotation_speed * delta)

func set_item(item: Item, quantity: int = 1):
	item_data = item
	
	if item == null or quantity <= 0:
		# Slot vide
		item_node.mesh = null
		quantity_label.text = ""
		return
	
	# Applique le modèle 3D
	item_node.mesh = item.world_mesh
	
	# Ajuste l'échelle pour que ça rentre bien dans le slot
	var scale = item.inventory_scale
	item_node.scale = Vector3(scale, scale, scale)
	
	# Affiche la quantité si > 1
	if quantity > 1:
		quantity_label.text = str(quantity)
	else:
		quantity_label.text = ""

func clear_slot():
	set_item(null, 0)
