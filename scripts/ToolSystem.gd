# ToolSystem.gd - Version mise à jour avec toolbar
extends Node
class_name ToolSystem

enum Tool {
	SEEDS,
	WATERING_CAN,
	SICKLE
}

var current_tool: Tool = Tool.SEEDS
@onready var interaction_ray: RayCast3D = get_parent().get_node("SpringArm3D/InteractionRay")

# Référence vers le panel d'outils
var tool_panel: SimpleToolPanel

func _ready():
	print("ToolSystem: Initialisation...")
	
	# Attendre un frame pour que l'UIManager soit prêt
	await get_tree().process_frame
	
	# Connecter à l'UI et créer la toolbar
	setup_toolbar()

func setup_toolbar():
	print("ToolSystem: Configuration de la toolbar...")
	
	# Créer le panel d'outils
	tool_panel = SimpleToolPanel.new()
	tool_panel.name = "ToolPanel"
	
	# Connecter le signal de changement d'outil
	tool_panel.tool_changed.connect(_on_tool_changed)
	
	# Ajouter le panel à l'UIManager
	if UIManager.instance:
		UIManager.instance.add_panel("tools", tool_panel)
		UIManager.show_ui("tools")
		print("ToolSystem: Toolbar ajoutée à l'UIManager")
	else:
		print("ToolSystem: ERREUR - UIManager non disponible")
		# Fallback : ajouter directement à la scène
		get_tree().current_scene.add_child(tool_panel)

func _on_tool_changed(new_tool: Tool):
	print("ToolSystem: Changement d'outil reçu: ", get_tool_name(new_tool))
	current_tool = new_tool
	
	# Ici vous pouvez ajouter des effets visuels ou sonores
	# pour indiquer le changement d'outil
	update_tool_display()

func update_tool_display():
	# Cette fonction peut être utilisée pour mettre à jour l'affichage
	# de l'outil dans le monde 3D (par exemple, changer le modèle dans la main du joueur)
	print("ToolSystem: Outil actuel: ", get_tool_name(current_tool))

func get_tool_name(tool: Tool) -> String:
	match tool:
		Tool.SEEDS:
			return "GRAINES"
		Tool.WATERING_CAN:
			return "ARROSOIR"
		Tool.SICKLE:
			return "FAUCILLE"
		_:
			return "INCONNU"

func get_current_tool() -> Tool:
	return current_tool

# Méthode pour utiliser l'outil actuel
func use_current_tool():
	match current_tool:
		Tool.SEEDS:
			use_seeds()
		Tool.WATERING_CAN:
			use_watering_can()
		Tool.SICKLE:
			use_sickle()

func use_seeds():
	print("ToolSystem: Utilisation des graines")
	# Logique pour planter des graines
	if interaction_ray and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		print("ToolSystem: Plantation sur ", collider.name)

func use_watering_can():
	print("ToolSystem: Utilisation de l'arrosoir")
	# Logique pour arroser
	if interaction_ray and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		print("ToolSystem: Arrosage de ", collider.name)

func use_sickle():
	print("ToolSystem: Utilisation de la faucille")
	# Logique pour récolter
	if interaction_ray and interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		print("ToolSystem: Récolte de ", collider.name)

# Méthode pour ajouter facilement de nouveaux outils
func add_new_tool(tool_name: String, tool_enum: Tool, icon: String):
	if tool_panel:
		tool_panel.add_tool(tool_name, tool_enum, icon)
		print("ToolSystem: Nouvel outil ajouté: ", tool_name)
