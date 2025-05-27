# Item.gd - Classe complète pour définir un objet
class_name Item
extends Resource

# Propriétés de base
@export var id: String = ""  # Identifiant unique (ex: "seed_bag")
@export var name: String = ""  # Nom affiché (ex: "Sac de graines")
@export var description: String = ""  # Description de l'objet

# Propriétés visuelles
@export var world_mesh: Mesh  # Modèle 3D (utilisé dans le monde et l'inventaire)
@export var inventory_scale: float = 1.0  # Échelle pour l'affichage dans l'inventaire

# Propriétés de gameplay
@export var stack_size: int = 64  # Nombre max dans une pile
@export var is_stackable: bool = true  # Peut-on les empiler ?
@export var rarity: String = "common"  # common, rare, epic, etc.

# Propriétés spécifiques au farming
@export var item_type: String = "tool"  # tool, seed, crop, resource
@export var durability: int = -1  # -1 = indestructible, sinon nombre d'utilisations

func _init(
	p_id: String = "",
	p_name: String = "",
	p_description: String = ""
):
	id = p_id
	name = p_name
	description = p_description

# Méthode pour créer une copie
func duplicate_item() -> Item:
	var new_item = Item.new()
	new_item.id = id
	new_item.name = name
	new_item.description = description
	new_item.world_mesh = world_mesh
	new_item.inventory_scale = inventory_scale
	new_item.stack_size = stack_size
	new_item.is_stackable = is_stackable
	new_item.rarity = rarity
	new_item.item_type = item_type
	new_item.durability = durability
	return new_item
