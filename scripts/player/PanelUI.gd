extends CanvasLayer

var inventory: PlayerInventory

# Called when the node enters the scene tree for the first time.
func _ready():
	print("🔧 PanelUI._ready() démarré")
	setup_inventory()
	
	# Debug
	await get_tree().process_frame
	await get_tree().process_frame
	
	if inventory:
		print("✅ Inventaire créé : ", inventory)
		if inventory.ui:
			print("✅ UI inventaire créée : ", inventory.ui)
		else:
			print("❌ Pas d'UI sur l'inventaire")
	else:
		print("❌ Pas d'inventaire créé")

func setup_inventory():
	inventory = PlayerInventory.new()
	add_child(inventory)

# === API INVENTAIRE POUR LES AUTRES SCRIPTS ===
func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	"""API publique pour ajouter des items"""
	if inventory:
		return inventory.pickup_item(item, quantity)
	return quantity

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	"""API publique pour retirer des items"""
	if inventory:
		return inventory.remove_item(item_id, quantity)
	return 0

func has_item_in_inventory(item_id: String, quantity: int = 1) -> bool:
	"""API publique pour vérifier les items"""
	if inventory:
		return inventory.has_item(item_id, quantity)
	return false
