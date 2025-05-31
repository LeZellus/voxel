# scripts/click_system/test/TestClickSystemManager.gd
extends Node
class_name TestClickSystemManager

var click_system: ClickSystemManager
var test_inventory: PlayerInventory
var test_hotbar: HotbarContainer

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
	
	print("✅ Actions de base enregistrées")

func connect_existing_inventory(inventory: PlayerInventory):
	"""Connecte l'inventaire existant au système de test"""
	if not inventory:
		print("❌ Inventaire null")
		return
	
	test_inventory = inventory
	
	# Enregistrer l'inventaire dans le système de clic
	click_system.register_container("player_inventory", inventory.controller)
	
	print("✅ Inventaire connecté au système de clic")

func connect_existing_hotbar(hotbar: HotbarContainer):
	"""Connecte la hotbar existante au système de test"""
	if not hotbar:
		print("❌ Hotbar null")
		return
	
	test_hotbar = hotbar
	
	# Enregistrer la hotbar dans le système de clic
	click_system.register_container("player_hotbar", hotbar.controller)
	
	print("✅ Hotbar connectée au système de clic")

func simulate_click_on_inventory_slot(slot_index: int, click_type: ClickContext.ClickType = ClickContext.ClickType.SIMPLE_LEFT_CLICK):
	"""Simule un clic sur un slot d'inventaire pour les tests"""
	if not test_inventory:
		print("❌ Inventaire de test non connecté")
		return
	
	var slot_data = test_inventory.controller.get_slot_info(slot_index)
	
	# Créer un faux événement de souris
	var fake_event = InputEventMouseButton.new()
	fake_event.button_index = MOUSE_BUTTON_LEFT
	fake_event.pressed = false
	
	# Simuler le clic avec le bon container_id
	click_system.handle_slot_click(slot_index, "test_inventory", slot_data, fake_event)

func print_test_info():
	"""Affiche les informations de test"""
	print("\n🧪 === INFORMATIONS DE TEST ===")
	print("📋 Actions disponibles:")
	print("   - Clic gauche: Déplacer un objet")
	print("   - Clic droit: Utiliser un objet")
	print("\n📋 Commandes de test:")
	print("   - Appuyez sur [T] pour tester un clic sur le slot 0")
	print("   - Appuyez sur [Y] pour tester un clic droit sur le slot 0")
	print("   - Appuyez sur [U] pour afficher l'état du système")

func _input(event):
	"""Gestion des touches de test"""
	if not event is InputEventKey:  # ← AJOUTER CETTE LIGNE
		return
	
	if not event.pressed:
		return
	
	match event.keycode:
		KEY_T:
			print("🧪 Test: Clic gauche sur slot 0")
			simulate_click_on_inventory_slot(0, ClickContext.ClickType.SIMPLE_LEFT_CLICK)
		
		KEY_Y:
			print("🧪 Test: Clic droit sur slot 0")
			simulate_click_on_inventory_slot(0, ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
		
		KEY_U:
			print("🧪 État du système:")
			if click_system:
				click_system.print_debug_info()
		
		KEY_I:
			print_test_info()
			
func connect_test_inventory(inventory_data: TestInventoryData):
	"""Connecte l'inventaire de test au système de clic"""
	if not inventory_data:
		print("❌ inventory_data null")
		return
	
	if not inventory_data.controller:
		print("❌ controller null dans inventory_data")
		return
	
	test_inventory = inventory_data  # Stocker la référence
	
	# Enregistrer dans le système de clic
	click_system.register_container("test_inventory", inventory_data.controller)
	
	print("✅ Inventaire de test connecté au système de clic")
			
func connect_test_hotbar(hotbar_data: TestHotbarData):
	"""Connecte la hotbar de test au système de clic"""
	if not hotbar_data:
		print("❌ hotbar_data null")
		return
	
	if not hotbar_data.controller:
		print("❌ controller null dans hotbar_data")
		return
	
	test_hotbar = hotbar_data  # Stocker la référence
	
	# Enregistrer dans le système de clic
	click_system.register_container("test_hotbar", hotbar_data.controller)
	
	print("✅ Hotbar de test connectée au système de clic")
