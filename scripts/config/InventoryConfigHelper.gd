class_name InventoryConfigHelper

static func apply_config_to_container(container: ClickableContainer, config_key: String):
	"""Applique toute la configuration à un container"""
	var config = InventoryConfig.get_inventory_config(config_key)
	if config.is_empty():
		return
		
	# Nom d'affichage
	container.update_inventory_name(config.display_name)
	
	# Visibilité par défaut
	if config.get("visible_by_default", false):
		container.call_deferred("show_ui")

static func get_ui_positioning_for_config(config_key: String) -> Dictionary:
	"""Retourne les infos de positionnement selon le type"""
	match config_key:
		"hotbar":
			return {"position": "top", "margin": 0.0}
		"main":
			return {"position": "center", "margin": 0.0}
		_:
			return {"position": "center", "margin": 0.0}
