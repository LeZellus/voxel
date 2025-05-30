# scripts/inventory/ui/HotbarUI.gd
class_name HotbarUI
extends Control

# === RÉUTILISE EXACTEMENT LA MÊME LOGIQUE QU'InventoryGridUI ===

signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)  
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var hotbar_grid: Control = $HotbarGrid
@onready var grid_container: GridContainer = $HotbarGrid/GridContainer

@export var slot_scene: PackedScene = preload("res://scenes/ui/InventorySlotUI.tscn")

const HOTBAR_SIZE = 9
const SLOT_SIZE = 64

var slots: Array[InventorySlotUI] = []
var hotbar_container: HotbarContainer
var inventory: Inventory 
var controller: InventoryController
var selected_slot_index: int = 0
var drag_manager: DragDropManager

func _ready():
	setup_grid()
	
	# IMPORTANT: Forcer l'affichage permanent
	show()
	visible = true
	
	# Positionner correctement en haut de l'écran
	_position_hotbar()

func _position_hotbar():
	"""Position la hotbar en haut centre de l'écran"""
	# Attendre que la taille soit calculée
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	var total_width = 608
	
	# Centrer horizontalement, positionner en haut
	position.x = (viewport_size.x - total_width) / 2
	position.y = 4  # 20px du haut
	size.x = total_width
	size.y = SLOT_SIZE
	
	print("🎯 Hotbar positionnée: %s (taille: %s)" % [position, size])

func setup_grid():
	"""COPIE EXACTE de InventoryGridUI.setup_grid()"""
	clear_existing_slots()
	
	if grid_container:
		grid_container.columns = HOTBAR_SIZE  # 9 au lieu de Constants.GRID_COLUMNS
	
	# Créer seulement 9 slots au lieu de Constants.INVENTORY_SIZE
	for i in HOTBAR_SIZE:
		create_slot(i)
	
	print("✅ Hotbar créée avec %d slots" % HOTBAR_SIZE)

func clear_existing_slots():
	"""COPIE EXACTE de InventoryGridUI.clear_existing_slots()"""
	for slot in slots:
		if slot and is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	for child in grid_container.get_children():
		child.queue_free()

func create_slot(index: int):
	"""COPIE EXACTE de InventoryGridUI.create_slot() avec taille adaptée"""
	if not slot_scene:
		push_error("Slot scene non définie dans HotbarUI !")
		return
	
	var slot_ui = slot_scene.instantiate()
	slot_ui.set_slot_index(index)
	
	# Seule différence : taille des slots
	slot_ui.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot_ui.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# MÊME logique de connexion des signaux
	if slot_ui.has_signal("slot_clicked"):
		slot_ui.slot_clicked.connect(_on_slot_clicked)
	if slot_ui.has_signal("slot_right_clicked"):
		slot_ui.slot_right_clicked.connect(_on_slot_right_clicked)
	if slot_ui.has_signal("slot_hovered"):
		slot_ui.slot_hovered.connect(_on_slot_hovered)
	if slot_ui.has_signal("drag_started"):
		slot_ui.drag_started.connect(_on_slot_drag_started)
	
	grid_container.add_child(slot_ui)
	slots.append(slot_ui)

# === SETUP HOTBAR (équivalent de setup_inventory) ===

func setup_hotbar(inv: Inventory, ctrl: InventoryController, container: HotbarContainer):
	"""Équivalent de InventoryUI.setup_inventory() - VERSION AVEC DRAG"""
	print("🔧 HotbarUI.setup_hotbar() démarré")
	
	inventory = inv
	controller = ctrl
	hotbar_container = container
	
	# IMPORTANT: Setup du drag manager AVANT les signaux
	await _setup_drag_manager()
	
	if inventory and inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	refresh_ui()
	set_selected_slot(0)
	
	print("✅ HotbarUI setup terminé")

# === MÉTHODES RÉUTILISÉES (copies exactes) ===

func update_all_slots(slots_data: Array):
	"""COPIE EXACTE de InventoryGridUI.update_all_slots()"""
	var max_slots = min(slots.size(), slots_data.size())
	
	for i in max_slots:
		if slots[i] and is_instance_valid(slots[i]):
			slots[i].update_slot(slots_data[i])

func refresh_ui():
	"""COPIE de InventoryUI.refresh_ui() adaptée"""
	if not controller:
		return
	
	var slots_data = []
	for i in HOTBAR_SIZE:
		slots_data.append(controller.get_slot_info(i))
	
	update_all_slots(slots_data)

func get_slot(slot_index: int) -> InventorySlotUI:
	"""COPIE EXACTE de InventoryGridUI.get_slot()"""
	if slot_index >= 0 and slot_index < slots.size():
		return slots[slot_index]
	return null

# === SÉLECTION VISUELLE (seule nouveauté) ===

func set_selected_slot(slot_index: int):
	"""Met en surbrillance le slot sélectionné"""
	selected_slot_index = slot_index
	
	# Utilise la méthode set_selected existante d'InventorySlotUI
	for i in slots.size():
		if slots[i]:
			slots[i].set_selected(i == slot_index)

# === GESTION DES SIGNAUX (copies exactes) ===

func _on_slot_clicked(slot_index: int, slot_ui: InventorySlotUI):
	if hotbar_container:
		hotbar_container.select_slot(slot_index)
	slot_clicked.emit(slot_index, slot_ui)

func _on_slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI):
	if hotbar_container:
		hotbar_container.use_selected_item()
	slot_right_clicked.emit(slot_index, slot_ui)

func _on_slot_hovered(slot_index: int, slot_ui: InventorySlotUI):
	slot_hovered.emit(slot_index, slot_ui)

func _on_slot_drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2):
	print("🎯 Hotbar: Slot drag started - slot %d" % slot_ui.get_slot_index())
	
	if not drag_manager:
		print("❌ Pas de drag manager - tentative de récupération...")
		_setup_drag_manager()
		await get_tree().process_frame
	
	if drag_manager and not slot_ui.is_empty():
		print("🎯 Démarrage du drag via drag manager")
		drag_manager.start_drag(slot_ui, mouse_pos)
	else:
		print("❌ Impossible de démarrer le drag")
		if not drag_manager:
			print("   - Drag manager manquant")
		if slot_ui.is_empty():
			print("   - Slot vide")

func _on_inventory_changed():
	refresh_ui()

func _setup_drag_manager():
	"""Configure le drag manager pour la hotbar - VERSION CORRIGÉE"""
	print("🔧 Setup drag manager hotbar démarré")
	
	# Attendre que tout soit initialisé
	await get_tree().process_frame
	
	# Méthode 1: Chercher le drag manager via PanelUI
	var panel_ui = _find_panel_ui()
	if panel_ui and panel_ui.has_method("get_inventory"):
		var main_inventory = panel_ui.get_inventory()
		if main_inventory and main_inventory.ui and main_inventory.ui.get("drag_manager"):
			drag_manager = main_inventory.ui.drag_manager
			print("✅ Drag manager récupéré via PanelUI")
		else:
			print("❌ Impossible de récupérer le drag manager via PanelUI")
	
	# Méthode 2: Chercher dans l'arbre de scène
	if not drag_manager:
		print("🔍 Recherche du drag manager dans l'arbre de scène...")
		drag_manager = _find_drag_manager_in_scene()
	
	# Méthode 3: En dernier recours, utiliser le drag manager du premier InventoryGridUI trouvé
	if not drag_manager:
		print("🔍 Recherche d'un InventoryGridUI existant...")
		var inventory_grid = _find_inventory_grid()
		if inventory_grid and inventory_grid.get_parent() and inventory_grid.get_parent().get("drag_manager"):
			drag_manager = inventory_grid.get_parent().drag_manager
			print("✅ Drag manager trouvé via InventoryGridUI")
	
	# Vérifier le résultat
	if drag_manager:
		# IMPORTANT: Ajouter cette hotbar aux grilles du drag manager
		drag_manager.set_inventory_grid(self)
		print("✅ Hotbar ajoutée au drag manager existant")
		
		# Connecter les signaux de drag
		_connect_drag_signals()
	else:
		print("❌ Aucun drag manager trouvé pour la hotbar")
		
func _find_panel_ui() -> Node:
	"""Trouve PanelUI dans l'arbre de scène"""
	var current = self
	while current:
		if current.name == "PanelUI" or "PanelUI" in current.name:
			return current
		current = current.get_parent()
		# Sécurité pour éviter de remonter trop loin
		if current is CanvasLayer or current.name == "MainScene":
			break
			
	# Chercher dans toute la scène si pas trouvé
	var root = get_tree().current_scene
	return _find_node_recursive(root, "PanelUI")
	
func _find_node_recursive(node: Node, name_pattern: String) -> Node:
	"""Recherche récursive d'un node par nom"""
	if node.name == name_pattern or name_pattern in node.name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, name_pattern)
		if result:
			return result
	
	return null

func _find_drag_manager_in_scene() -> DragDropManager:
	"""Cherche un DragDropManager dans toute la scène"""
	var root = get_tree().current_scene
	return _find_drag_manager_recursive(root)

func _find_drag_manager_recursive(node: Node) -> DragDropManager:
	"""Recherche récursive d'un DragDropManager"""
	if node is DragDropManager:
		return node
	
	for child in node.get_children():
		var result = _find_drag_manager_recursive(child)
		if result:
			return result
	
	return null

func _find_inventory_grid() -> Control:
	"""Trouve un InventoryGridUI dans la scène"""
	var root = get_tree().current_scene
	return _find_inventory_grid_recursive(root)

func _find_inventory_grid_recursive(node: Node) -> Control:
	"""Recherche récursive d'un InventoryGridUI"""
	if node.get_script() and "InventoryGridUI" in str(node.get_script().resource_path):
		return node
	
	for child in node.get_children():
		var result = _find_inventory_grid_recursive(child)
		if result:
			return result
	
	return null

func _connect_drag_signals():
	"""Connecte les signaux de drag si pas déjà fait"""
	if not drag_manager:
		return
	
	# Vérifier si les signaux sont déjà connectés pour éviter les doublons
	if not drag_manager.drag_started.is_connected(_on_drag_started):
		drag_manager.drag_started.connect(_on_drag_started)
		print("🔗 Signal drag_started connecté")
	
	if not drag_manager.drag_completed.is_connected(_on_drag_completed):
		drag_manager.drag_completed.connect(_on_drag_completed)
		print("🔗 Signal drag_completed connecté")
	
	if not drag_manager.drag_cancelled.is_connected(_on_drag_cancelled):
		drag_manager.drag_cancelled.connect(_on_drag_cancelled)
		print("🔗 Signal drag_cancelled connecté")

# Ajouter ces méthodes de gestion des signaux :
func _on_drag_started(slot_index: int):
	print("🎯 Hotbar: Drag démarré depuis slot %d" % slot_index)

func _on_drag_completed(from_slot: int, to_slot: int):
	print("🎯 Hotbar: Drag terminé %d -> %d" % [from_slot, to_slot])

func _on_drag_cancelled():
	print("🎯 Hotbar: Drag annulé")
