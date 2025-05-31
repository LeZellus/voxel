# TestClickSystem.gd
extends Node

@onready var test_manager: Node = $TestClickSystemManager
@onready var inventory_data: Node = $TestData/TestInventoryData  # ← Node au lieu de TestInventoryData
@onready var hotbar_data: Node = $TestData/TestHotbarData        # ← Node au lieu de TestHotbarData
@onready var inventory_ui: Control = $UI/InventoryUI
@onready var hotbar_ui: Control = $UI/HotbarUI

func _ready():
	print("🎬 Test Click System démarré")
	
	# Attendre plus longtemps que tout soit prêt
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Vérifications de debug
	print("🔍 Debug nodes:")
	print("  - inventory_data: ", inventory_data)
	print("  - hotbar_data: ", hotbar_data)
	print("  - inventory_ui: ", inventory_ui)
	print("  - hotbar_ui: ", hotbar_ui)
	
	# Vérifier que les données sont prêtes
	if not inventory_data or not inventory_data.get("inventory"):
		print("❌ Inventory data pas prêt, attente...")
		await _wait_for_data()
	
	# Connecter les données aux UI
	setup_ui_connections()
	
	print("✅ Test configuré")
	
	connect_to_click_system()
	
	print("✅ Test configuré")
	
func connect_to_click_system():
	"""Connecte au système de clic"""
	if not test_manager:
		print("❌ test_manager introuvable")
		return
	
	# Utiliser les nouvelles méthodes
	if test_manager.has_method("connect_test_inventory"):
		test_manager.connect_test_inventory(inventory_data)
		print("✅ Inventaire connecté au système de clic")
	
	if test_manager.has_method("connect_test_hotbar"):
		test_manager.connect_test_hotbar(hotbar_data)
		print("✅ Hotbar connectée au système de clic")


func _wait_for_data():
	"""Attend que les données soient prêtes"""
	var max_attempts = 10
	var attempts = 0
	
	while attempts < max_attempts:
		await get_tree().process_frame
		
		if inventory_data and inventory_data.get("inventory") and hotbar_data and hotbar_data.get("inventory"):
			print("✅ Données prêtes après %d tentatives" % attempts)
			return
		
		attempts += 1
		print("⏳ Tentative %d/%d..." % [attempts, max_attempts])
	
	print("❌ Timeout - données pas prêtes")

func setup_ui_connections():
	"""Connecte les données aux UI existantes"""
	if not inventory_data or not inventory_data.get("inventory"):
		print("❌ inventory_data pas prêt")
		return
	
	if inventory_ui and inventory_ui.has_method("setup_inventory"):
		inventory_ui.setup_inventory(inventory_data.inventory, inventory_data.controller)
		# FORCER L'AFFICHAGE
		inventory_ui.visible = true
		inventory_ui.show()
		print("✅ InventoryUI connecté et affiché")
	
	if hotbar_ui and hotbar_ui.has_method("setup_hotbar"):
		hotbar_ui.setup_hotbar(hotbar_data.inventory, hotbar_data.controller, hotbar_data)
		# FORCER L'AFFICHAGE
		hotbar_ui.visible = true
		hotbar_ui.show()
		print("✅ HotbarUI connecté et affiché")
