# WorldItem.gd - Objet physique dans le monde
extends RigidBody3D

@export var item_data: Item  # La ressource Item qu'on va créer

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	setup_visual()
	setup_physics()

func setup_visual():
	if not item_data:
		print("Erreur: Aucune donnée d'item assignée!")
		return
	
	# Applique le modèle 3D
	if item_data.world_mesh:
		mesh_instance.mesh = item_data.world_mesh
		print("Modèle 3D appliqué pour: ", item_data.name)
	else:
		print("Attention: Pas de modèle 3D pour ", item_data.name)

func setup_physics():
	if not item_data or not item_data.world_mesh:
		return
	
	# Crée la collision automatiquement
	var shape = item_data.world_mesh.create_trimesh_shape()
	collision_shape.shape = shape
	
	# Rend l'objet un peu plus léger
	mass = 0.5

# Fonction appelée quand le joueur interagit
func pickup() -> Item:
	print("Ramassage de: ", item_data.name)
	var item_copy = item_data.duplicate_item()
	queue_free()  # Supprime l'objet du monde
	return item_copy

# Pour l'interaction
func get_item_name() -> String:
	return item_data.name if item_data else "Objet inconnu"
