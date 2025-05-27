# InventoryUI.gd - Interface d'inventaire avec objets 3D
# À sauvegarder dans : res://scripts/ui/InventoryUI.gd
extends Control

@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/InventoryGrid
@onready var panel: Panel = $Panel

var inventory: Inventory
var slot_scenes: Array[Control] = []
var inventory_manager: Node  # Référence vers le gestionnaire
var selected_slot: int = -1  # Slot actuellement sélectionné

# Pour l'instant, on commente cette ligne car on n'a pas encore créé la scène
# var slot_3d_scene: PackedScene = preload("res://scenes/ui/InventorySlot3D.tscn")

func _ready():
	# Cache l'inventaire au démarrage
	visible = false
	
	# IMPORTANT: Permet de fonctionner même quand d'autres éléments sont en pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pour recevoir les inputs globaux
	set_process_input(true)
	
	# Configure la grille (9 colonnes comme Minecraft)
	if inventory_grid:
		inventory_grid.columns = 9
		# Crée les slots visuels (version simple pour l'instant)
		create_simple_slots()

func _input(event):
	# Gère la fermeture uniquement si l'inventaire est visible
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			print("E détecté depuis l'UI - fermeture inventaire")
			toggle_inventory()
			get_viewport().set_input_as_handled()  # Empêche d'autres nœuds de traiter cet input
		
		# Navigation au clavier dans l'inventaire
		elif event.keycode == KEY_RIGHT:
			navigate_selection(1, 0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT:
			navigate_selection(-1, 0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			navigate_selection(0, 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			navigate_selection(0, -1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER:
			if selected_slot >= 0:
				show_item_info(selected_slot)
			get_viewport().set_input_as_handled()

# Navigation au clavier
func navigate_selection(dx: int, dy: int):
	if selected_slot < 0:
		selected_slot = 0
	else:
		var cols = 9
		var current_row = selected_slot / cols
		var current_col = selected_slot % cols
		
		var new_col = current_col + dx
		var new_row = current_row + dy
		
		# Wraparound horizontal
		if new_col < 0:
			new_col = cols - 1
		elif new_col >= cols:
			new_col = 0
		
		# Limitez vertical
		var max_rows = (slot_scenes.size() + cols - 1) / cols
		if new_row < 0:
			new_row = 0
		elif new_row >= max_rows:
			new_row = max_rows - 1
		
		var new_slot = new_row * cols + new_col
		if new_slot < slot_scenes.size():
			_on_slot_clicked(new_slot)

func setup_inventory(inv: Inventory, manager: Node):
	inventory = inv
	inventory_manager = manager
	inventory.slot_changed.connect(_on_slot_changed)
	update_all_slots()

func create_simple_slots():
	if not inventory_grid:
		return
		
	slot_scenes.clear()
	
	# Supprime les anciens slots
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Crée 36 slots simples (4 rangées de 9)
	for i in range(36):
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(64, 64)
		slot_button.flat = true
		
		# Style du slot normal
		var style_normal = StyleBoxFlat.new()
		style_normal.border_width_left = 2
		style_normal.border_width_top = 2
		style_normal.border_width_right = 2
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color.GRAY
		style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		
		# Style du slot sélectionné
		var style_selected = StyleBoxFlat.new()
		style_selected.border_width_left = 3
		style_selected.border_width_top = 3
		style_selected.border_width_right = 3
		style_selected.border_width_bottom = 3
		style_selected.border_color = Color.YELLOW
		style_selected.bg_color = Color(0.2, 0.2, 0.1, 0.9)
		
		# Style du slot au survol
		var style_hover = StyleBoxFlat.new()
		style_hover.border_width_left = 2
		style_hover.border_width_top = 2
		style_hover.border_width_right = 2
		style_hover.border_width_bottom = 2
		style_hover.border_color = Color.WHITE
		style_hover.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		
		slot_button.add_theme_stylebox_override("normal", style_normal)
		slot_button.add_theme_stylebox_override("hover", style_hover)
		slot_button.add_theme_stylebox_override("pressed", style_selected)
		
		# Label pour afficher le nom de l'item
		var label = Label.new()
		label.text = ""
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 10)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Le label ne bloque pas les clics
		
		slot_button.add_child(label)
		
		# Connecte le signal de clic
		slot_button.pressed.connect(_on_slot_clicked.bind(i))
		
		inventory_grid.add_child(slot_button)
		slot_scenes.append(slot_button)

# Fonction appelée quand un slot est cliqué
func _on_slot_clicked(slot_index: int):
	print("Slot ", slot_index, " cliqué")
	
	# Désélectionne l'ancien slot
	if selected_slot >= 0 and selected_slot < slot_scenes.size():
		var old_slot = slot_scenes[selected_slot]
		var style_normal = StyleBoxFlat.new()
		style_normal.border_width_left = 2
		style_normal.border_width_top = 2
		style_normal.border_width_right = 2
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color.GRAY
		style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		old_slot.add_theme_stylebox_override("normal", style_normal)
	
	# Sélectionne le nouveau slot
	selected_slot = slot_index
	var new_slot = slot_scenes[selected_slot]
	var style_selected = StyleBoxFlat.new()
	style_selected.border_width_left = 3
	style_selected.border_width_top = 3
	style_selected.border_width_right = 3
	style_selected.border_width_bottom = 3
	style_selected.border_color = Color.YELLOW
	style_selected.bg_color = Color(0.2, 0.2, 0.1, 0.9)
	new_slot.add_theme_stylebox_override("normal", style_selected)
	
	# Affiche les infos de l'item sélectionné
	show_item_info(slot_index)

func toggle_inventory():
	visible = !visible
	
	print("InventoryUI toggle - maintenant ", "visible" if visible else "caché")
	
	if visible:
		# Le jeu continue, on libère juste la souris
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		print("Souris libérée")
	else:
		# On capture la souris pour le mouvement de caméra
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("Souris capturée")
		
		# Désélectionne l'item quand on ferme l'inventaire
		if selected_slot >= 0:
			selected_slot = -1
			# Remet tous les slots en style normal
			for i in range(slot_scenes.size()):
				var slot = slot_scenes[i]
				var style_normal = StyleBoxFlat.new()
				style_normal.border_width_left = 2
				style_normal.border_width_top = 2
				style_normal.border_width_right = 2
				style_normal.border_width_bottom = 2
				style_normal.border_color = Color.GRAY
				style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.8)
				slot.add_theme_stylebox_override("normal", style_normal)

func _on_slot_changed(slot_index: int):
	update_slot_visual(slot_index)

func update_slot_visual(slot_index: int):
	if slot_index < 0 or slot_index >= slot_scenes.size():
		return
	
	var slot = inventory.get_slot(slot_index)
	var slot_ui = slot_scenes[slot_index]
	var label = slot_ui.get_child(0) as Label
	
	if slot.is_empty():
		label.text = ""
		slot_ui.tooltip_text = ""
	else:
		# Affiche le nom de l'item et la quantité
		var text = slot.item.name
		if slot.quantity > 1:
			text += "\nx" + str(slot.quantity)
		label.text = text
		
		# Tooltip avec description
		slot_ui.tooltip_text = slot.item.name + "\n" + slot.item.description + "\nQuantité: " + str(slot.quantity)

# Affiche les informations de l'item sélectionné
func show_item_info(slot_index: int):
	if not inventory:
		return
		
	var slot = inventory.get_slot(slot_index)
	if slot.is_empty():
		print("Slot vide sélectionné")
		return
	
	print("=== ITEM SÉLECTIONNÉ ===")
	print("Nom: ", slot.item.name)
	print("Description: ", slot.item.description)
	print("Type: ", slot.item.item_type)
	print("Quantité: ", slot.quantity)
	print("Empilable: ", slot.item.is_stackable)
	print("Taille max pile: ", slot.item.stack_size)
	print("========================")

# Fonction pour obtenir l'item actuellement sélectionné
func get_selected_item() -> Item:
	if selected_slot >= 0 and inventory:
		var slot = inventory.get_slot(selected_slot)
		if not slot.is_empty():
			return slot.item
	return null

# Fonction pour obtenir la quantité de l'item sélectionné
func get_selected_quantity() -> int:
	if selected_slot >= 0 and inventory:
		var slot = inventory.get_slot(selected_slot)
		return slot.quantity
	return 0

func update_all_slots():
	if not inventory:
		return
	
	for i in range(min(inventory.size, slot_scenes.size())):
		update_slot_visual(i)

# Méthode pour ajouter des items (appelée par le test)
func add_test_item(item: Item, quantity: int = 1):
	if inventory:
		inventory.add_item(item, quantity)
