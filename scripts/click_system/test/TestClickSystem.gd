# scripts/click_system/test/TestClickSystem.gd - VERSION CORRIGÉE
extends Node

@onready var test_manager: TestClickSystemManager = $TestClickSystemManager
@onready var inventory_data: TestInventoryData = $InventoryData/TestInventoryData
@onready var hotbar_data: TestHotbarData = $InventoryData/TestHotbarData

# UI Test (on va créer nos propres UI de test)
var test_inventory_ui: Control
var test_hotbar_ui: Control

# Stocker les grilles directement (plus robuste)
var inventory_grid: GridContainer
var hotbar_grid: HBoxContainer

func _ready():
	print("🎬 Test Click System démarré")
	await get_tree().process_frame
	
	# Attendre que les données soient prêtes
	await _wait_for_test_data()
	
	# Créer les UI de test
	await _create_test_uis()
	
	# Connecter au système de clic
	_connect_to_click_system()
	
	_show_instructions()

func _wait_for_test_data():
	"""Attend que les données de test soient prêtes"""
	var max_wait = 30  # 30 frames max
	var frames = 0
	
	while frames < max_wait:
		if inventory_data and inventory_data.inventory and hotbar_data and hotbar_data.inventory:
			print("✅ Données de test prêtes")
			return
		
		await get_tree().process_frame
		frames += 1
	
	print("❌ Timeout - données de test non prêtes")

func _create_test_uis():
	"""Crée des UI de test simples"""
	print("🎨 Création des UI de test")
	
	# Créer un CanvasLayer pour les UI
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "TestUI"
	add_child(ui_layer)
	
	# Créer UI inventaire de test
	test_inventory_ui = _create_test_inventory_ui()
	ui_layer.add_child(test_inventory_ui)
	
	# Créer UI hotbar de test
	test_hotbar_ui = _create_test_hotbar_ui()
	ui_layer.add_child(test_hotbar_ui)
	
	print("✅ UI de test créées")

func _create_test_inventory_ui() -> Control:
	"""Crée une UI d'inventaire simple pour les tests"""
	var ui = Control.new()
	ui.name = "TestInventoryUI"
	ui.size = Vector2(400, 300)
	ui.position = Vector2(50, 50)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.3, 0.9)
	bg.size = ui.size
	ui.add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "TEST INVENTORY (Click System)"
	title.position = Vector2(10, 10)
	ui.add_child(title)
	
	# Grid container pour les slots
	inventory_grid = GridContainer.new()  # ← Stocker la référence directement
	inventory_grid.name = "GridContainer"
	inventory_grid.columns = 5
	inventory_grid.position = Vector2(10, 40)
	inventory_grid.add_theme_constant_override("h_separation", 4)
	inventory_grid.add_theme_constant_override("v_separation", 4)
	ui.add_child(inventory_grid)
	
	# Créer les slots avec ClickableSlotUI
	for i in range(10):  # 10 slots de test
		var slot = _create_clickable_slot(i)
		inventory_grid.add_child(slot)  # ← Utiliser la référence stockée
		
		# Connecter le signal au test manager
		slot.slot_clicked.connect(_on_inventory_slot_clicked)
	
	return ui

func _create_test_hotbar_ui() -> Control:
	"""Crée une UI de hotbar simple pour les tests"""
	var ui = Control.new()
	ui.name = "TestHotbarUI"
	ui.size = Vector2(600, 80)
	ui.position = Vector2(50, 400)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.3, 0.2, 0.2, 0.9)
	bg.size = ui.size
	ui.add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "TEST HOTBAR (Click System)"
	title.position = Vector2(10, 10)
	ui.add_child(title)
	
	# Grid horizontal pour les slots
	hotbar_grid = HBoxContainer.new()  # ← Stocker la référence directement
	hotbar_grid.name = "HBoxContainer"
	hotbar_grid.position = Vector2(10, 40)
	hotbar_grid.add_theme_constant_override("separation", 4)
	ui.add_child(hotbar_grid)
	
	# Créer 9 slots de hotbar
	for i in range(9):
		var slot = _create_clickable_slot(i)
		hotbar_grid.add_child(slot)  # ← Utiliser la référence stockée
		
		# Connecter le signal au test manager
		slot.slot_clicked.connect(_on_hotbar_slot_clicked)
	
	return ui

func _create_clickable_slot(index: int) -> ClickableSlotUI:
	"""Crée un slot clickable pour les tests"""
	var slot = ClickableSlotUI.new()
	slot.set_slot_index(index)
	slot.custom_minimum_size = Vector2(64, 64)
	slot.size = Vector2(64, 64)
	
	# Ajouter les composants manuellement pour les tests
	_setup_slot_components(slot)
	
	return slot

func _setup_slot_components(slot: ClickableSlotUI):
	"""Configure les composants d'un slot manuellement"""
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.09, 0.125, 0.22, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	slot.add_child(bg)
	
	# ItemIcon
	var icon = TextureRect.new()
	icon.name = "ItemIcon"
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.offset_left = 8
	icon.offset_top = 8
	icon.offset_right = -8
	icon.offset_bottom = -8
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)
	
	# QuantityLabel
	var qty_label = Label.new()
	qty_label.name = "QuantityLabel"
	qty_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	qty_label.offset_left = -20
	qty_label.offset_top = -20
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.visible = false
	slot.add_child(qty_label)
	
	# Button (invisible, pour capturer les clics)
	var button = Button.new()
	button.name = "Button"
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.add_child(button)

func _connect_to_click_system():
	"""Connecte les UI au système de clic"""
	print("🔗 Connexion au système de clic")
	
	# Enregistrer les containers dans le test manager
	test_manager.connect_test_inventory(inventory_data)
	test_manager.connect_test_hotbar(hotbar_data)
	
	# Mettre à jour l'affichage des slots avec les données
	_refresh_inventory_display()
	_refresh_hotbar_display()
	
	print("✅ Système de clic connecté")

func _refresh_inventory_display():
	"""Met à jour l'affichage de l'inventaire de test"""
	if not inventory_grid:  # ← Utiliser la référence directe
		return
	
	var slots = inventory_grid.get_children()
	
	for i in range(min(slots.size(), 10)):
		var slot = slots[i]
		var slot_data = inventory_data.controller.get_slot_info(i)
		slot.update_slot(slot_data)

func _refresh_hotbar_display():
	"""Met à jour l'affichage de la hotbar de test"""
	if not hotbar_grid:  # ← Utiliser la référence directe
		return
	
	var slots = hotbar_grid.get_children()
	
	for i in range(min(slots.size(), 9)):
		var slot = slots[i]
		var slot_data = hotbar_data.controller.get_slot_info(i)
		slot.update_slot(slot_data)

# === GESTIONNAIRES DE CLICS ===

func _on_inventory_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic pour l'inventaire"""
	print("🎯 Clic inventaire: slot %d, bouton %d" % [slot_index, mouse_event.button_index])
	
	var slot_data = inventory_data.controller.get_slot_info(slot_index)
	test_manager.click_system.handle_slot_click(
		slot_index, 
		inventory_data.get_container_id(), 
		slot_data, 
		mouse_event
	)
	
	# Rafraîchir l'affichage
	call_deferred("_refresh_inventory_display")

func _on_hotbar_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic pour la hotbar"""
	print("🎯 Clic hotbar: slot %d, bouton %d" % [slot_index, mouse_event.button_index])
	
	var slot_data = hotbar_data.controller.get_slot_info(slot_index)
	test_manager.click_system.handle_slot_click(
		slot_index, 
		hotbar_data.get_container_id(), 
		slot_data, 
		mouse_event
	)
	
	# Rafraîchir l'affichage
	call_deferred("_refresh_hotbar_display")

func _show_instructions():
	"""Affiche les instructions de test"""
	print("\n🧪 === INSTRUCTIONS DE TEST ===")
	print("🎯 Clic GAUCHE sur un slot avec item = Déplacer")
	print("🎯 Clic DROIT sur un slot avec item = Utiliser")
	print("📦 Items disponibles dans l'inventaire et hotbar")
	print("✅ Test prêt !")

# === INPUT POUR TESTS MANUELS ===

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_R:
			print("🔄 Refresh display")
			_refresh_inventory_display()
			_refresh_hotbar_display()
		
		KEY_S:
			print("📊 État du click system:")
			test_manager.click_system.print_debug_info()
