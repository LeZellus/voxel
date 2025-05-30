# DebugInventoryPipeline.gd - Script de debug complet
extends CanvasLayer

var player_inventory: PlayerInventory

func _ready():
	print("🔬 DÉBUT DU DEBUG PIPELINE INVENTAIRE")
	
	setup_input_actions()
	await get_tree().process_frame
	await debug_complete_pipeline()

func setup_input_actions():
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_TAB
		InputMap.action_add_event("toggle_inventory", key_event)

func debug_complete_pipeline():
	print("\n📦 ÉTAPE 1: Création PlayerInventory")
	player_inventory = PlayerInventory.new()
	add_child(player_inventory)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Debug de l'initialisation
	print("✅ PlayerInventory créé")
	print("   - Inventory: %s" % str(player_inventory.inventory))
	print("   - Controller: %s" % str(player_inventory.controller))
	print("   - UI: %s" % str(player_inventory.ui))
	
	if not player_inventory.inventory:
		print("❌ ARRÊT: Inventory est null")
		return
	
	print("\n🎯 ÉTAPE 2: Test de l'ajout d'items")
	await test_item_addition()
	
	print("\n🔍 ÉTAPE 3: Debug des slots")
	debug_slots()
	
	print("\n🖥️ ÉTAPE 4: Debug de l'UI")
	await debug_ui()
	
	print("\n✅ Debug terminé - Utilisez Tab pour ouvrir l'inventaire")

func test_item_addition():
	# Créer un item simple
	var test_item = Item.new("test", "Item Test")
	test_item.max_stack_size = 5
	test_item.is_stackable = true
	
	# Créer une icône simple
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.BLUE)
	var texture = ImageTexture.new()
	texture.set_image(image)
	test_item.icon = texture
	
	print("🎯 Item créé:")
	print("   - ID: %s" % test_item.id)
	print("   - Name: %s" % test_item.name)
	print("   - Icon: %s" % str(test_item.icon))
	print("   - Icon valid: %s" % str(test_item.icon is Texture2D))
	
	# Test 1: Ajout direct à l'inventory
	print("\n🔬 Test 1: Ajout direct à l'inventory")
	var surplus = player_inventory.inventory.add_item(test_item, 3)
	print("   - Surplus retourné: %d" % surplus)
	print("   - Items ajoutés: %d" % (3 - surplus))
	
	# Vérification immédiate
	var count = player_inventory.inventory.get_item_count("test")
	print("   - Count dans inventory: %d" % count)
	
	# Test 2: Via le PlayerInventory
	print("\n🔬 Test 2: Via PlayerInventory.add_item")
	var surplus2 = player_inventory.add_item(test_item, 2)
	print("   - Surplus retourné: %d" % surplus2)
	
	var count2 = player_inventory.inventory.get_item_count("test")
	print("   - Count total: %d" % count2)

func debug_slots():
	print("\n🔍 DEBUG DES SLOTS:")
	
	for i in range(5):
		var slot = player_inventory.inventory.get_slot(i)
		print("\n   Slot %d:" % i)
		print("     - Slot object: %s" % str(slot))
		print("     - Is empty: %s" % str(slot.is_empty()))
		
		if not slot.is_empty():
			print("     - Item: %s" % str(slot.get_item()))
			print("     - Item name: %s" % str(slot.get_item().name))
			print("     - Quantity: %d" % slot.get_quantity())
			print("     - Icon: %s" % str(slot.get_item().icon))
		
		# Test du controller
		if player_inventory.controller:
			var slot_info = player_inventory.controller.get_slot_info(i)
			print("     - Controller info: %s" % str(slot_info))

func debug_ui():
	print("\n🖥️ DEBUG DE L'UI:")
	
	if not player_inventory.ui:
		print("❌ UI est null!")
		return
	
	print("✅ UI trouvée: %s" % str(player_inventory.ui))
	
	# Chercher l'InventoryGridUI
	var grid_ui = find_inventory_grid(player_inventory.ui)
	if not grid_ui:
		print("❌ InventoryGridUI non trouvée!")
		return
	
	print("✅ InventoryGridUI trouvée: %s" % str(grid_ui))
	print("   - Slots count: %d" % grid_ui.get_slot_count())
	
	# Forcer un refresh
	print("\n🔄 Force refresh de l'UI")
	if player_inventory.ui.has_method("refresh_ui"):
		player_inventory.ui.refresh_ui()
		print("✅ Refresh appelé")
	
	# Debug des slots UI
	await get_tree().process_frame
	for i in range(min(5, grid_ui.get_slot_count())):
		var slot_ui = grid_ui.get_slot(i)
		if slot_ui:
			print("   Slot UI %d:" % i)
			print("     - Object: %s" % str(slot_ui))
			print("     - Is empty: %s" % str(slot_ui.is_empty()))
			print("     - Data: %s" % str(slot_ui.get_slot_data()))

func find_inventory_grid(node: Node) -> InventoryGridUI:
	"""Trouve récursivement l'InventoryGridUI"""
	if node is InventoryGridUI:
		return node
	
	for child in node.get_children():
		var result = find_inventory_grid(child)
		if result:
			return result
	
	return null

func _input(event):
	if not player_inventory:
		return
	
	if event.is_action_pressed("toggle_inventory"):
		player_inventory.toggle_ui()
		
		# Debug supplémentaire à l'ouverture
		if player_inventory.is_open:
			print("\n🔍 DEBUG À L'OUVERTURE:")
			await get_tree().process_frame
			debug_ui_state()
	
	elif event.is_action_pressed("ui_accept"):
		# Forcer un refresh
		print("\n🔄 FORCE REFRESH (Espace pressé)")
		if player_inventory.ui and player_inventory.ui.has_method("refresh_ui"):
			player_inventory.ui.refresh_ui()
	
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func debug_ui_state():
	print("🖥️ État de l'UI au moment de l'ouverture:")
	
	if not player_inventory.ui:
		print("❌ UI null")
		return
	
	var grid_ui = find_inventory_grid(player_inventory.ui)
	if not grid_ui:
		print("❌ Grid UI non trouvée")
		return
	
	print("✅ Grid UI visible: %s" % str(grid_ui.visible))
	print("✅ Grid UI slots: %d" % grid_ui.get_slot_count())
	
	# Vérifier si les slots ont des données
	for i in range(min(3, grid_ui.get_slot_count())):
		var slot_ui = grid_ui.get_slot(i)
		if slot_ui:
			var data = slot_ui.get_slot_data()
			print("   Slot %d data: %s" % [i, str(data)])
			
			if slot_ui.item_icon:
				print("   Slot %d icon texture: %s" % [i, str(slot_ui.item_icon.texture)])
				print("   Slot %d icon visible: %s" % [i, str(slot_ui.item_icon.visible)])
