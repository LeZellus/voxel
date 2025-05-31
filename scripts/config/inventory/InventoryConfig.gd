# scripts/config/InventoryConfig.gd
class_name InventoryConfig
extends RefCounted

# === CONFIGURATION DES INVENTAIRES ===
const INVENTORIES = {
	"main": {
		"id": "player_inventory",
		"display_name": "INVENTAIRE PRINCIPAL", 
		"size": Constants.INVENTORY_SIZE,
		"ui_scene": "res://scenes/click_system/ui/MainInventoryUI.tscn",
		"visible_by_default": false
	},
	"hotbar": {
		"id": "player_hotbar",
		"display_name": "BARRE D'ACTIONS",
		"size": 9,
		"ui_scene": "res://scenes/click_system/ui/HotbarUI.tscn",
		"visible_by_default": true,
		"is_hotbar": true
	}
}

# === GETTERS PRATIQUES ===

static func get_inventory_config(key: String) -> Dictionary:
	"""Récupère la config d'un inventaire"""
	return INVENTORIES.get(key, {})

static func get_inventory_id(key: String) -> String:
	"""Récupère l'ID d'un inventaire"""
	var config = get_inventory_config(key)
	return config.get("id", "")

static func get_inventory_display_name(key: String) -> String:
	"""Récupère le nom d'affichage d'un inventaire"""
	var config = get_inventory_config(key)
	return config.get("display_name", "")

static func get_inventory_size(key: String) -> int:
	"""Récupère la taille d'un inventaire"""
	var config = get_inventory_config(key)
	return config.get("size", 10)

static func get_inventory_ui_scene(key: String) -> String:
	"""Récupère le chemin de l'UI d'un inventaire"""
	var config = get_inventory_config(key)
	return config.get("ui_scene", "")

static func is_visible_by_default(key: String) -> bool:
	"""Vérifie si l'inventaire doit être visible par défaut"""
	var config = get_inventory_config(key)
	return config.get("visible_by_default", false)

# === VALIDATION ===

static func validate_config():
	print("✅ Configuration des inventaires:")
	print("   - Inventaire principal: %d slots (%dx%d)" % [
		Constants.MAIN_INVENTORY_SLOTS, 
		Constants.GRID_COLUMNS, 
		Constants.GRID_ROWS
	])
	print("   - Hotbar: %d slots" % Constants.HOTBAR_SIZE)
	
	for key in INVENTORIES.keys():
		var config = INVENTORIES[key]
		assert(config.has("id"), "ID manquant pour: " + key)
		assert(config.has("size"), "Taille manquante pour: " + key)
		assert(config.get("size", 0) > 0, "Taille invalide pour: " + key)

# === DEBUG ===

static func print_all_configs():
	print("\n📦 Configuration des inventaires:")
	for key in INVENTORIES.keys():
		var config = INVENTORIES[key]
		print("   %s: %s (%d slots)" % [key, config.display_name, config.size])
