# UIManager.gd - Version mise à jour avec gestion toolbar
extends CanvasLayer
class_name UIManager

# Singleton
static var instance: UIManager

# Stockage des panels
var ui_panels: Dictionary = {}

func _ready():
	print("UIManager: Initialisation...")
	
	# Pattern Singleton
	if instance == null:
		instance = self
		print("UIManager: Instance créée")
		setup_ui_layer()
	else:
		print("UIManager: Instance déjà existante, suppression")
		queue_free()

func setup_ui_layer():
	# Configuration du layer UI
	layer = 100  # Au-dessus du jeu
	follow_viewport_enabled = true

# Méthode pour ajouter un panel
func add_panel(panel_name: String, panel_node: Control):
	print("UIManager: Ajout du panel ", panel_name)
	
	if panel_name in ui_panels:
		print("UIManager: ATTENTION - Panel ", panel_name, " déjà existant, remplacement")
		ui_panels[panel_name].queue_free()
	
	ui_panels[panel_name] = panel_node
	add_child(panel_node)
	
	# Configuration spécifique pour la toolbar
	if panel_name == "tools":
		setup_toolbar_positioning(panel_node)

func setup_toolbar_positioning(toolbar: Control):
	# Positionnement spécifique pour la toolbar à gauche
	toolbar.anchors_preset = Control.PRESET_LEFT_WIDE
	toolbar.offset_left = 20
	toolbar.offset_right = 100
	toolbar.offset_top = 50
	toolbar.offset_bottom = -50

# Méthodes de base pour l'affichage
func show_panel(panel_name: String):
	print("UIManager: Affichage du panel ", panel_name)
	if panel_name in ui_panels:
		ui_panels[panel_name].visible = true
		ui_panels[panel_name].modulate.a = 1.0
		print("UIManager: Panel ", panel_name, " affiché")
	else:
		print("UIManager: ERREUR - Panel ", panel_name, " non trouvé")

func hide_panel(panel_name: String):
	print("UIManager: Masquage du panel ", panel_name)
	if panel_name in ui_panels:
		ui_panels[panel_name].visible = false
		print("UIManager: Panel ", panel_name, " masqué")
	else:
		print("UIManager: ERREUR - Panel ", panel_name, " non trouvé")

func toggle_panel(panel_name: String):
	if is_panel_visible(panel_name):
		hide_panel(panel_name)
	else:
		show_panel(panel_name)

func is_panel_visible(panel_name: String) -> bool:
	if panel_name in ui_panels:
		return ui_panels[panel_name].visible
	return false

# Méthode pour obtenir un panel spécifique
func get_panel(panel_name: String) -> Control:
	if panel_name in ui_panels:
		return ui_panels[panel_name]
	return null

# Méthodes statiques pour accès global
static func show_ui(panel_name: String):
	if instance:
		instance.show_panel(panel_name)

static func hide_ui(panel_name: String):
	if instance:
		instance.hide_panel(panel_name)

static func toggle_ui(panel_name: String):
	if instance:
		instance.toggle_panel(panel_name)

static func get_ui_panel(panel_name: String) -> Control:
	if instance:
		return instance.get_panel(panel_name)
	return null

# Méthode pour gérer la visibilité globale de l'UI
func set_ui_visibility(visible: bool):
	for panel in ui_panels.values():
		panel.visible = visible

# Méthode statique pour la visibilité globale
static func set_global_ui_visibility(visible: bool):
	if instance:
		instance.set_ui_visibility(visible)
