# scripts/inventory/containers/PlayerInventory.gd - VERSION FINALE CORRIGÉE
class_name PlayerInventory
extends BaseContainer

func _init():
	# Utiliser le nouveau constructeur de BaseContainer
	super(
		"player_inventory", 
		Constants.INVENTORY_SIZE, 
		"Inventaire du Joueur",
		"res://scenes/ui/InventoryUI.tscn"
	)

func _ready():
	# Setup automatique de l'UI D'ABORD
	var success = await setup_ui()
	if success:
		print("✅ PlayerInventory UI créée avec succès")
		
		# Configuration spécifique au joueur APRÈS
		#setup_input_toggle("toggle_inventory")
		print("✅ PlayerInventory initialisé avec succès")
	else:
		print("❌ Erreur lors de l'initialisation de PlayerInventory")

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
	
	if surplus > 0:
		print("⚠️ Inventaire plein! %d %s laissés" % [surplus, item.name])
	
	return surplus

func drop_item(item_id: String, quantity: int = 1) -> int:
	"""Jette un item avec feedback"""
	var removed = remove_item(item_id, quantity)
	
	if removed > 0:
		_play_ui_sound("item_drop")
		print("📤 Jeté: %s x%d" % [item_id, removed])
	
	return removed

# === INTÉGRATION AVEC LE SYSTÈME DE JEU ===
func _on_action_performed(action_type: String, result: bool):
	"""Feedback spécifique aux actions du joueur"""
	match action_type:
		"move_item":
			_play_ui_sound("ui_item_move" if result else "ui_error")
		"add_item":
			if result:
				_play_ui_sound("item_pickup")
		"remove_item":
			if result:
				_play_ui_sound("item_use")
