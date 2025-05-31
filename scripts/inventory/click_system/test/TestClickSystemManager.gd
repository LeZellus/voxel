# scripts/click_system/test/TestClickSystemManager.gd - AVEC CROSS-CONTAINER
extends Node
class_name TestClickSystemManager

var click_system: ClickSystemManager
var test_inventory: TestInventoryData
var test_hotbar: TestHotbarData

func _ready():
	print("🧪 TestClickSystemManager démarré")
	setup_test_environment()

func setup_test_environment():
	"""Configure l'environnement de test step by step"""
	
	# Étape 1: Créer le système de clic
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	# Étape 2: Enregistrer les actions de base
	register_basic_actions()
	
	# Attendre un frame puis continuer
	await get_tree().process_frame
	
	print("✅ Système de test configuré")
	print_test_info()

func register_basic_actions():
	"""Enregistre seulement les actions de base pour commencer"""
	
	# Action de déplacement sur clic gauche simple
	var move_action = MoveItemAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_LEFT_CLICK, move_action)
	
	# Action d'utilisation sur clic droit simple
	var use_action = UseItemAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_RIGHT_CLICK, use_action)
	
	# NOUVEAU: Action cross-container (même type que move, mais priorité sur cross-container)
	var cross_action = CrossContainerAction.new(click_system)
	click_system.register_action(ClickContext.ClickType.SIMPLE_LEFT_CLICK, cross_action)
	
	print("✅ Actions de base + cross-container enregistrées")

func simulate_click_on_inventory_slot(slot_index: int, click_type: ClickContext.ClickType = ClickContext.ClickType.SIMPLE_LEFT_CLICK):
	if not test_inventory:
		print("❌ Inventaire de test non connecté")
		return
	
	var slot_data = test_inventory.controller.get_slot_info(slot_index)
	var fake_event = InputEventMouseButton.new()
	fake_event.pressed = false
	
	match click_type:
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			fake_event.button_index = MOUSE_BUTTON_RIGHT
		_:
			fake_event.button_index = MOUSE_BUTTON_LEFT
	
	click_system.handle_slot_click(slot_index, "test_inventory", slot_data, fake_event)

# NOUVEAU: Simuler un clic sur la hotbar
func simulate_click_on_hotbar_slot(slot_index: int, click_type: ClickContext.ClickType = ClickContext.ClickType.SIMPLE_LEFT_CLICK):
	if not test_hotbar:
		print("❌ Hotbar de test non connectée")
		return
	
	var slot_data = test_hotbar.controller.get_slot_info(slot_index)
	var fake_event = InputEventMouseButton.new()
	fake_event.pressed = false
	
	match click_type:
		ClickContext.ClickType.SIMPLE_RIGHT_CLICK:
			fake_event.button_index = MOUSE_BUTTON_RIGHT
		_:
			fake_event.button_index = MOUSE_BUTTON_LEFT
	
	click_system.handle_slot_click(slot_index, "test_hotbar", slot_data, fake_event)

func print_test_info():
	"""Affiche les informations de test"""
	print("\n🧪 === INFORMATIONS DE TEST CROSS-CONTAINER ===")
	print("📋 Actions disponibles:")
	print("   - Clic gauche: Déplacer un objet (même conteneur ou cross-container)")
	print("   - Clic droit: Utiliser un objet")
	print("\n📋 Commandes de test:")
	print("   [T] - Clic inventaire slot 0")
	print("   [Y] - Clic droit inventaire slot 0")
	print("   [1,2,3] - Destination inventaire slots 1,2,3")
	print("   [H] - Clic hotbar slot 0")
	print("   [J] - Clic droit hotbar slot 0")
	print("   [4,5,6] - Destination hotbar slots 1,2,3")
	print("   [U] - État système")
	print("\n🎯 Test cross-container:")
	print("   1. [T] puis [4] = Inventaire slot 0 → Hotbar slot 1")
	print("   2. [H] puis [1] = Hotbar slot 0 → Inventaire slot 1")

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		# === INVENTAIRE ===
		KEY_T:
			print("🧪 Test: Clic inventaire slot 0")
			simulate_click_on_inventory_slot(0, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_Y:
			print("🧪 Test: Clic droit inventaire slot 0")
			simulate_click_on_inventory_slot(0, ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		
		KEY_1:
			print("🧪 Test: Destination inventaire slot 1")
			simulate_click_on_inventory_slot(1, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_2:
			print("🧪 Test: Destination inventaire slot 2")
			simulate_click_on_inventory_slot(2, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_3:
			print("🧪 Test: Destination inventaire slot 3")
			simulate_click_on_inventory_slot(3, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		# === HOTBAR ===
		KEY_H:
			print("🧪 Test: Clic hotbar slot 0")
			simulate_click_on_hotbar_slot(0, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_J:
			print("🧪 Test: Clic droit hotbar slot 0")
			simulate_click_on_hotbar_slot(0, ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		
		KEY_4:
			print("🧪 Test: Destination hotbar slot 1")
			simulate_click_on_hotbar_slot(1, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_5:
			print("🧪 Test: Destination hotbar slot 2")
			simulate_click_on_hotbar_slot(2, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_6:
			print("🧪 Test: Destination hotbar slot 3")
			simulate_click_on_hotbar_slot(3, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		# === SYSTÈME ===
		KEY_U:
			print("📊 État du click system:")
			click_system.print_debug_info()
			
func connect_test_inventory(inventory_data: TestInventoryData):
	"""Connecte l'inventaire de test au système de clic"""
	if not inventory_data or not inventory_data.controller:
		print("❌ inventory_data invalide")
		return
	
	test_inventory = inventory_data
	click_system.register_container("test_inventory", inventory_data.controller)
	print("✅ Inventaire de test connecté au système de clic")
			
func connect_test_hotbar(hotbar_data: TestHotbarData):
	"""Connecte la hotbar de test au système de clic"""
	if not hotbar_data or not hotbar_data.controller:
		print("❌ hotbar_data invalide")
		return
	
	test_hotbar = hotbar_data
	click_system.register_container("test_hotbar", hotbar_data.controller)
	print("✅ Hotbar de test connectée au système de clic")
