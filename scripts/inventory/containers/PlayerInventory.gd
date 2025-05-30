# scripts/inventory/containers/PlayerInventory.gd - VERSION CORRIGÉE
class_name PlayerInventory
extends BaseContainer

func _init():
	super(
		"player_inventory", 
		Constants.INVENTORY_SIZE, 
		"Inventaire du Joueur",
		"res://scenes/ui/InventoryUI.tscn"
	)

func _ready():
	print("🚀 PlayerInventory _ready() appelé")
	
	# Setup automatique de l'UI
	var success = await setup_ui()
	if success:
		print("✅ UI setup réussi")
		# IMPORTANT: Setup immédiat de l'inventaire dans l'UI
		await _setup_ui_inventory()
	else:
		print("❌ Erreur lors de l'initialisation de PlayerInventory")

func _setup_ui_inventory():
	"""Configure l'UI avec l'inventaire et le contrôleur"""
	if not ui:
		print("❌ UI non disponible pour setup")
		return
	
	if not ui.has_method("setup_inventory"):
		print("❌ UI n'a pas la méthode setup_inventory")
		return
	
	print("🔧 Configuration de l'UI avec inventory et controller")
	ui.setup_inventory(inventory, controller)
	
	# Forcer un premier refresh
	await get_tree().process_frame
	if ui.has_method("refresh_ui"):
		ui.refresh_ui()
		print("🔄 Premier refresh de l'UI effectué")

# === SPÉCIALISATIONS JOUEUR ===
func _on_container_opened():
	"""Comportement spécifique à l'ouverture de l'inventaire joueur"""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_container_closed():
	"""Comportement spécifique à la fermeture de l'inventaire joueur"""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# === API SPÉCIFIQUE JOUEUR ===
func pickup_item(item: Item, quantity: int = 1) -> int:
	"""Ramasse un item avec feedback audio"""
	var surplus = add_item(item, quantity)
	var picked_up = quantity - surplus
	
	if picked_up > 0:
		_play_ui_sound("item_pickup")
		print("📦 Ramassé: %s x%d" % [item.name, picked_up])
		
		# Forcer un refresh de l'UI après ajout
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
	
	if surplus > 0:
		print("⚠️ Inventaire plein! %d %s laissés" % [surplus, item.name])
	
	return surplus

func drop_item(item_id: String, quantity: int = 1) -> int:
	"""Jette un item avec feedback"""
	var removed = remove_item(item_id, quantity)
	
	if removed > 0:
		_play_ui_sound("item_drop")
		print("📤 Jeté: %s x%d" % [item_id, removed])
		
		# Forcer un refresh de l'UI après suppression
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()
	
	return removed

# === OVERRIDE pour forcer le refresh ===
func add_item(item: Item, quantity: int = 1) -> int:
	var result = super.add_item(item, quantity)
	
	# Forcer un refresh de l'UI après chaque ajout
	if ui and ui.has_method("refresh_ui"):
		call_deferred("_force_ui_refresh")
	
	return result

func _force_ui_refresh():
	"""Force un refresh de l'UI avec debug"""
	if ui and ui.has_method("refresh_ui"):
		print("🔄 Force refresh UI")
		ui.refresh_ui()

# === INTÉGRATION AVEC LE SYSTÈME DE JEU ===
func _on_action_performed(action_type: String, result: bool):
	"""Feedback spécifique aux actions du joueur"""
	match action_type:
		"move_item":
			_play_ui_sound("ui_item_move" if result else "ui_error")
		"add_item":
			if result:
				_play_ui_sound("item_pickup")
				_force_ui_refresh()
		"remove_item":
			if result:
				_play_ui_sound("item_use")
				_force_ui_refresh()

# === DEBUG METHODS ===
func debug_state():
	"""Affiche l'état complet pour debug"""
	print("\n📊 DEBUG PlayerInventory:")
	print("   - Inventory: %s" % str(inventory))
	print("   - Controller: %s" % str(controller))
	print("   - UI: %s" % str(ui))
	
	if inventory:
		print("   - Items count: %d" % inventory.get_used_slots_count())
		print("   - Total slots: %d" % inventory.get_size())
	
	if ui:
		print("   - UI visible: %s" % str(ui.visible))
		print("   - UI setup: %s" % str(ui.get("is_setup") if ui.has_method("get") else "unknown"))
