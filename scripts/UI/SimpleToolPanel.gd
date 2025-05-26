# SimpleToolPanel.gd
extends Control
class_name SimpleToolPanel

# Signal émis quand l'outil change
signal tool_changed(new_tool: ToolSystem.Tool)

# Référence vers le système d'outils
var tool_system: ToolSystem

# Variables pour la toolbar
var tool_buttons: Array[Button] = []
var current_selected: int = 0

# Configuration des outils
var tools_data = [
	{"name": "Graines", "tool": ToolSystem.Tool.SEEDS, "icon": "🌱", "key": "1"},
	{"name": "Arrosoir", "tool": ToolSystem.Tool.WATERING_CAN, "icon": "🚿", "key": "2"},
	{"name": "Faucille", "tool": ToolSystem.Tool.SICKLE, "icon": "🔪", "key": "3"}
]

func _ready():
	print("SimpleToolPanel: Initialisation...")
	setup_ui()
	setup_input()

func setup_ui():
	# Configuration du panel principal
	custom_minimum_size = Vector2(80, 200)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Positionnement à gauche
	anchors_preset = Control.PRESET_LEFT_WIDE
	offset_left = 20
	offset_right = 100
	
	# Container vertical pour les boutons
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# Création des boutons d'outils
	for i in range(tools_data.size()):
		var tool_data = tools_data[i]
		var button = create_tool_button(tool_data, i)
		tool_buttons.append(button)
		vbox.add_child(button)
	
	# Sélectionner le premier outil par défaut
	select_tool(0)

func create_tool_button(tool_data: Dictionary, index: int) -> Button:
	var button = Button.new()
	
	# Configuration du bouton
	button.custom_minimum_size = Vector2(60, 60)
	button.text = tool_data.icon + "\n" + str(index + 1)
	button.tooltip_text = tool_data.name + " (" + tool_data.key + ")"
	
	# Style du bouton
	button.add_theme_font_size_override("font_size", 12)
	
	# Connexion du signal
	button.pressed.connect(_on_tool_button_pressed.bind(index))
	
	return button

func _on_tool_button_pressed(index: int):
	select_tool(index)

func select_tool(index: int):
	if index < 0 or index >= tools_data.size():
		return
	
	print("SimpleToolPanel: Sélection de l'outil ", index)
	
	# Mise à jour de la sélection visuelle
	update_button_selection(index)
	
	# Émission du signal de changement d'outil
	var selected_tool = tools_data[index].tool
	current_selected = index
	tool_changed.emit(selected_tool)

func update_button_selection(selected_index: int):
	# Reset tous les boutons
	for i in range(tool_buttons.size()):
		var button = tool_buttons[i]
		if i == selected_index:
			# Bouton sélectionné
			button.modulate = Color.YELLOW
			button.add_theme_stylebox_override("normal", create_selected_style())
		else:
			# Bouton normal
			button.modulate = Color.WHITE
			button.remove_theme_stylebox_override("normal")

func create_selected_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 0, 0.3)  # Jaune semi-transparent
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.YELLOW
	return style

func setup_input():
	# Permettre au control de recevoir les inputs
	set_process_input(true)

func _input(event):
	if not visible:
		return
	
	# Gestion des touches numériques (1-3)
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		
		match key_code:
			KEY_1:
				select_tool(0)
			KEY_2:
				select_tool(1)
			KEY_3:
				select_tool(2)
	
	# Gestion de la molette de la souris
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_tool(-1)  # Outil précédent
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_tool(1)   # Outil suivant

func cycle_tool(direction: int):
	var new_index = (current_selected + direction) % tools_data.size()
	if new_index < 0:
		new_index = tools_data.size() - 1
	select_tool(new_index)

# Méthode pour ajouter de nouveaux outils facilement
func add_tool(name: String, tool: ToolSystem.Tool, icon: String):
	var new_tool_data = {
		"name": name,
		"tool": tool,
		"icon": icon,
		"key": str(tools_data.size() + 1)
	}
	tools_data.append(new_tool_data)
	
	# Recréer l'UI si elle existe déjà
	if tool_buttons.size() > 0:
		setup_ui()

# Méthode pour obtenir l'outil actuellement sélectionné
func get_current_tool() -> ToolSystem.Tool:
	if current_selected < tools_data.size():
		return tools_data[current_selected].tool
	return ToolSystem.Tool.SEEDS
