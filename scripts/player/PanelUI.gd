# scripts/player/PanelUI.gd - MÉTHODES D'ACCÈS POUR CROSS-CONTAINER
extends CanvasLayer

var inventory: PlayerInventory
var hotbar: HotbarContainer

func _ready():
	print("🔧 PanelUI._ready() démarré")
	setup_inventory()
	setup_hotbar()
	setup_input()
	setup_hotbar_input()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	call_deferred("add_test_items")
	debug_containers()

func setup_inventory():
	inventory = PlayerInventory.new()
	add_child(inventory)

func setup_hotbar():
	print("🎯 Setup hotbar démarré")
	hotbar = HotbarContainer.new()
	add_child(hotbar)
	
	hotbar.item_selected.connect(_on_hotbar_item_selected)
	hotbar.hotbar_item_used.connect(_on_hotbar_item_used)
	
	call_deferred("_connect_cross_container_drag")
	
	print("✅ Hotbar créée et connectée")

func setup_input():
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_E
		InputMap.action_add_event("toggle_inventory", key_event)
		print("✅ Action toggle_inventory créée (E)")

func setup_hotbar_input():
	for i in range(1, 10):
		var action_name = "hotbar_slot_" + str(i)
		
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
		
		InputMap.add_action(action_name)
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_1 + (i - 1)
		InputMap.action_add_event(action_name, key_event)
		print("✅ Action %s créée (touche %d)" % [action_name, i])

func _input(event):
	if not inventory or not hotbar:
		return
	
	# Toggle inventaire UNIQUEMENT
	if event.is_action_pressed("toggle_inventory"):
		inventory.toggle_ui()
		print("🔄 Toggle inventaire depuis PanelUI")
		return
	
	# Sélection des slots hotbar (touches 1-9)
	for i in range(1, 10):
		var action_name = "hotbar_slot_" + str(i)
		if event.is_action_pressed(action_name):
			hotbar.select_slot(i - 1)
			print("🎯 Slot %d sélectionné par touche %d" % [i - 1, i])
			return
	
	# Utilisation de l'item sélectionné
	if event.is_action_pressed("ui_accept"):
		var used = hotbar.use_selected_item()
		if used:
			print("🎯 Item utilisé depuis la hotbar")

# === MÉTHODES D'ACCÈS POUR CROSS-CONTAINER ===

func get_inventory() -> PlayerInventory:
	"""Retourne l'inventaire principal"""
	return inventory

func get_hotbar() -> HotbarContainer:
	"""Retourne la hotbar"""
	return hotbar

func get_inventory_controller() -> InventoryController:
	"""Retourne le contrôleur de l'inventaire principal"""
	if inventory:
		return inventory.controller
	return null

func get_hotbar_controller() -> InventoryController:
	"""Retourne le contrôleur de la hotbar"""
	if hotbar:
		return hotbar.controller
	return null

func get_inventory_inventory() -> Inventory:
	"""Retourne l'objet Inventory de l'inventaire principal"""
	if inventory:
		return inventory.inventory
	return null

func get_hotbar_inventory() -> Inventory:
	"""Retourne l'objet Inventory de la hotbar"""
	if hotbar:
		return hotbar.inventory
	return null

# === SIGNAUX DE LA HOTBAR ===

func _on_hotbar_item_selected(slot_index: int, item: Item):
	if item:
		print("🎯 Item sélectionné: %s (slot %d)" % [item.name, slot_index])
	else:
		print("🎯 Slot vide sélectionné: %d" % slot_index)

func _on_hotbar_item_used(slot_index: int, item: Item):
	print("🎯 Item utilisé: %s (slot %d)" % [item.name, slot_index])
	
	match item.item_type:
		Item.ItemType.CONSUMABLE:
			_use_consumable_item(item)
		Item.ItemType.TOOL:
			_equip_tool(item)
		Item.ItemType.RESOURCE:
			_use_resource_item(item)
		_:
			print("Type d'item non géré: %s" % str(item.item_type))

func _use_consumable_item(item: Item):
	print("🍎 Consommable utilisé: %s" % item.name)

func _equip_tool(item: Item):
	print("🔨 Outil équipé: %s" % item.name)

func _use_resource_item(item: Item):
	print("🪵 Ressource utilisée: %s" % item.name)

# === API PUBLIQUE ===

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	if inventory:
		return inventory.pickup_item(item, quantity)
	return quantity

func add_item_to_hotbar(item: Item, quantity: int = 1) -> int:
	if hotbar:
		return hotbar.add_item(item, quantity)
	return quantity

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	if inventory:
		return inventory.remove_item(item_id, quantity)
	return 0

func has_item_in_inventory(item_id: String, quantity: int = 1) -> bool:
	if inventory:
		return inventory.has_item(item_id, quantity)
	return false

func has_item_in_hotbar(item_id: String, quantity: int = 1) -> bool:
	if hotbar:
		return hotbar.has_item(item_id, quantity)
	return false

func transfer_to_hotbar(item_id: String, quantity: int = 1) -> bool:
	if not inventory or not hotbar:
		return false
	
	var removed = inventory.remove_item(item_id, quantity)
	if removed > 0:
		var item_resource = inventory.inventory._find_item_by_id(item_id)
		if item_resource:
			var surplus = hotbar.add_item(item_resource, removed)
			if surplus > 0:
				inventory.add_item(item_resource, surplus)
			return removed > surplus
	
	return false

# === DEBUG ===

func debug_containers():
	print("\n📊 DEBUG PanelUI:")
	
	if inventory:
		print("   📦 Inventaire principal: ✅")
		print("      - Slots utilisés: %d/%d" % [
			inventory.inventory.get_used_slots_count(),
			inventory.inventory.size
		])
	else:
		print("   📦 Inventaire principal: ❌")
	
	if hotbar:
		print("   🎯 Hotbar: ✅")
		print("      - Slot sélectionné: %d" % hotbar.get_selected_slot())
		print("      - Item sélectionné: %s" % (
			hotbar.get_selected_item().name if hotbar.get_selected_item() else "aucun"
		))
		print("      - Slots utilisés: %d/9" % hotbar.inventory.get_used_slots_count())
	else:
		print("   🎯 Hotbar: ❌")

func get_selected_hotbar_item() -> Item:
	if hotbar:
		return hotbar.get_selected_item()
	return null

func get_selected_hotbar_slot() -> int:
	if hotbar:
		return hotbar.get_selected_slot()
	return -1

func add_test_items():
	if not inventory or not hotbar:
		return
	
	var test_items = []
	
	for i in range(3):
		var item = Item.new()
		item.id = "test_item_%d" % i
		item.name = "Item Test %d" % (i + 1)
		item.max_stack_size = 10
		item.is_stackable = true
		test_items.append(item)
	
	for item in test_items:
		inventory.add_item(item, 5)
	
	hotbar.add_item(test_items[0], 3)
	hotbar.add_item(test_items[1], 2)
	
	print("🧪 Items de test ajoutés")

func _connect_cross_container_drag():
	"""Connecte le drag & drop entre inventaire et hotbar"""
	await get_tree().process_frame
	
	if inventory and inventory.ui and hotbar and hotbar.ui:
		var main_drag_manager = inventory.ui.drag_manager
		if main_drag_manager:
			# Ajouter la hotbar au système de drag
			main_drag_manager.set_inventory_grid(hotbar.ui)
			print("✅ Cross-container drag configuré")
	else:
		print("❌ Impossible de configurer le cross-container drag")
