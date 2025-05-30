# scripts/player/PanelUI.gd - VERSION AVEC HOTBAR
extends CanvasLayer

var inventory: PlayerInventory
var hotbar: HotbarContainer  # NOUVEAU

func _ready():
	print("🔧 PanelUI._ready() démarré")
	setup_inventory()
	setup_hotbar()      # NOUVEAU
	setup_input()
	setup_hotbar_input() # NOUVEAU
	
	# Debug
	await get_tree().process_frame
	await get_tree().process_frame
	
	call_deferred("add_test_items")
	debug_containers()

func setup_inventory():
	"""Configuration de l'inventaire principal (inchangé)"""
	inventory = PlayerInventory.new()
	add_child(inventory)

func setup_hotbar():
	"""Configuration de la hotbar"""
	print("🎯 Setup hotbar démarré")
	hotbar = HotbarContainer.new()
	add_child(hotbar)
	
	# Connecter les signaux de la hotbar
	hotbar.item_selected.connect(_on_hotbar_item_selected)
	hotbar.hotbar_item_used.connect(_on_hotbar_item_used)
	
	print("✅ Hotbar créée et connectée")

func setup_input():
	"""Configure l'action d'input pour l'inventaire (inchangé)"""
	if not InputMap.has_action("toggle_inventory"):
		InputMap.add_action("toggle_inventory")
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_TAB
		InputMap.action_add_event("toggle_inventory", key_event)
		print("✅ Action toggle_inventory créée (Tab)")

func setup_hotbar_input():
	"""Configure les actions d'input pour la hotbar (touches 1-9)"""
	for i in range(1, 10):  # Touches 1 à 9
		var action_name = "hotbar_slot_" + str(i)
		
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var key_event = InputEventKey.new()
			key_event.keycode = KEY_1 + (i - 1)  # KEY_1, KEY_2, etc.
			InputMap.action_add_event(action_name, key_event)
			print("✅ Action %s créée" % action_name)

func _input(event):
	"""Gestion des inputs pour inventaire ET hotbar"""
	if not inventory or not hotbar:
		return
	
	# Toggle inventaire (inchangé)
	if event.is_action_pressed("toggle_inventory"):
		inventory.toggle_ui()
		print("🔄 Toggle inventaire depuis PanelUI")
	
	# Sélection des slots hotbar (NOUVEAU)
	for i in range(1, 10):
		var action_name = "hotbar_slot_" + str(i)
		if event.is_action_pressed(action_name):
			hotbar.select_slot(i - 1)  # Les touches 1-9 correspondent aux slots 0-8
			print("🎯 Slot %d sélectionné" % (i - 1))
			break
	
	# Utilisation de l'item sélectionné (NOUVEAU)
	if event.is_action_pressed("ui_accept"):  # Entrée ou espace
		var used = hotbar.use_selected_item()
		if used:
			print("🎯 Item utilisé depuis la hotbar")

# === SIGNAUX DE LA HOTBAR ===

func _on_hotbar_item_selected(slot_index: int, item: Item):
	"""Appelé quand un item de la hotbar est sélectionné"""
	if item:
		print("🎯 Item sélectionné: %s (slot %d)" % [item.name, slot_index])
		# Ici vous pouvez ajouter de la logique spécifique
		# Par exemple, changer l'outil du joueur
	else:
		print("🎯 Slot vide sélectionné: %d" % slot_index)

func _on_hotbar_item_used(slot_index: int, item: Item):
	"""Appelé quand un item de la hotbar est utilisé"""
	print("🎯 Item utilisé: %s (slot %d)" % [item.name, slot_index])
	
	# Ici vous pouvez ajouter la logique d'utilisation selon le type d'item
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
	"""Logique pour utiliser un consommable"""
	print("🍎 Consommable utilisé: %s" % item.name)
	# Exemple: récupérer de la vie, etc.

func _equip_tool(item: Item):
	"""Logique pour équiper un outil"""
	print("🔨 Outil équipé: %s" % item.name)
	# Exemple: changer l'outil du ToolSystem

func _use_resource_item(item: Item):
	"""Logique pour utiliser une ressource"""
	print("🪵 Ressource utilisée: %s" % item.name)
	# Exemple: construction, craft, etc.

# === API INVENTAIRE (inchangé) ===

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	"""API publique pour ajouter des items à l'inventaire principal"""
	if inventory:
		return inventory.pickup_item(item, quantity)
	return quantity

func add_item_to_hotbar(item: Item, quantity: int = 1) -> int:
	"""NOUVEAU: API publique pour ajouter des items directement à la hotbar"""
	if hotbar:
		return hotbar.add_item(item, quantity)
	return quantity

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	"""API publique pour retirer des items de l'inventaire principal"""
	if inventory:
		return inventory.remove_item(item_id, quantity)
	return 0

func has_item_in_inventory(item_id: String, quantity: int = 1) -> bool:
	"""API publique pour vérifier les items dans l'inventaire principal"""
	if inventory:
		return inventory.has_item(item_id, quantity)
	return false

func has_item_in_hotbar(item_id: String, quantity: int = 1) -> bool:
	"""NOUVEAU: API publique pour vérifier les items dans la hotbar"""
	if hotbar:
		return hotbar.has_item(item_id, quantity)
	return false

# === TRANSFERT ENTRE INVENTAIRE ET HOTBAR ===

func transfer_to_hotbar(item_id: String, quantity: int = 1) -> bool:
	"""Transfère un item de l'inventaire vers la hotbar"""
	if not inventory or not hotbar:
		return false
	
	# Retirer de l'inventaire principal
	var removed = inventory.remove_item(item_id, quantity)
	if removed > 0:
		# Ajouter à la hotbar
		var surplus = hotbar.add_item(inventory.inventory.find_item_by_id(item_id), removed)
		if surplus > 0:
			# Remettre le surplus dans l'inventaire
			inventory.add_item(inventory.inventory.find_item_by_id(item_id), surplus)
		return removed > surplus
	
	return false

# === DEBUG ===

func debug_containers():
	"""Affiche l'état des conteneurs pour debug"""
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

# === MÉTHODES POUR L'INTÉGRATION AVEC LE JEU ===

func get_selected_hotbar_item() -> Item:
	"""Retourne l'item actuellement sélectionné dans la hotbar"""
	if hotbar:
		return hotbar.get_selected_item()
	return null

func get_selected_hotbar_slot() -> int:
	"""Retourne l'index du slot sélectionné dans la hotbar"""
	if hotbar:
		return hotbar.get_selected_slot()
	return -1
	
	
func add_test_items():
	"""Fonction de test - à supprimer plus tard"""
	if not inventory or not hotbar:
		return
	
	# Créer des items de test (vous devrez adapter selon vos ressources Item)
	var test_items = []
	
	# Si vous avez des ressources Item, utilisez-les
	# Sinon, créez des items basiques pour le test
	for i in range(3):
		var item = Item.new()
		item.id = "test_item_%d" % i
		item.name = "Item Test %d" % (i + 1)
		item.max_stack_size = 10
		item.is_stackable = true
		test_items.append(item)
	
	# Ajouter à l'inventaire principal
	for item in test_items:
		inventory.add_item(item, 5)
	
	# Ajouter quelques items directement à la hotbar
	hotbar.add_item(test_items[0], 3)
	hotbar.add_item(test_items[1], 2)
	
	print("🧪 Items de test ajoutés")
