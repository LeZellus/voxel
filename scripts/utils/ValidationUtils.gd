# ValidationUtils.gd - Utilitaires de validation réutilisables
class_name ValidationUtils
extends RefCounted

# Validation avec logging automatique
static func validate_node(node: Node, node_name: String, context: String = "") -> bool:
	if node == null:
		var message = "Node manquant: %s" % node_name
		if context != "":
			message += " dans %s" % context
		print("ERREUR: ", message)
		return false
	return true

static func validate_resource(resource: Resource, resource_name: String, context: String = "") -> bool:
	if resource == null:
		var message = "Resource manquante: %s" % resource_name  
		if context != "":
			message += " dans %s" % context
		print("ERREUR: ", message)
		return false
	return true

# Validation avec fallback automatique
static func get_node_safe(parent: Node, path: String, fallback: Node = null) -> Node:
	var node = parent.get_node_or_null(path)
	if node == null:
		node = parent.find_child(path.get_file(), true, false)
		if node == null and fallback != null:
			print("ATTENTION: Utilisation du fallback pour ", path)
			return fallback
		elif node == null:
			print("ERREUR: Node introuvable: ", path)
	return node

# Validation audio
static func validate_audio_setup(player: AudioStreamPlayer, sound: AudioStream, operation: String = "") -> bool:
	if not validate_node(player, "AudioStreamPlayer", operation):
		return false
		
	if not validate_resource(sound, "AudioStream", operation):
		return false
		
	return true

# Utilitaire pour les ranges/bounds
static func clamp_and_warn(value: float, min_val: float, max_val: float, context: String = "") -> float:
	if value < min_val or value > max_val:
		var original = value
		value = clamp(value, min_val, max_val)
		print("ATTENTION: Valeur corrigée de %f à %f pour %s" % [original, value, context])
	return value
	
# === NOUVELLES MÉTHODES POUR INVENTAIRE ===

static func validate_container_interface(container, required_methods: Array, context: String = "") -> bool:
	"""Valide qu'un container a les méthodes requises"""
	if not validate_node(container, "Container", context):
		return false
		
	for method in required_methods:
		if not container.has_method(method):
			print("ERREUR: Méthode manquante '%s' dans %s" % [str(method), context])
			return false
	return true

static func validate_ui_component(component, component_name: String, parent_context: String = "") -> bool:
	"""Validation spécialisée pour composants UI d'inventaire"""
	if component == null:
		var message = "Composant UI manquant: %s" % component_name
		if parent_context != "":
			message += " dans %s" % parent_context
		print("ERREUR: ", message)
		return false
	return true

static func validate_inventory_setup(inventory, controller, context: String = "") -> bool:
	"""Valide un setup complet d'inventaire"""
	if not validate_resource(inventory, "Inventory", context):
		return false
		
	if not validate_node(controller, "Controller", context):
		return false
		
	return true

# === VALIDATION AVEC AUTO-CORRECTION ===

static func find_ui_component_safe(parent: Node, paths: Array, component_name: String) -> Node:
	"""Trouve un composant UI avec fallback et logging"""
	for path in paths:
		var component = parent.get_node_or_null(path as String)
		if component:
			return component
	
	print("ATTENTION: %s introuvable dans %s. Chemins tentés: %s" % [component_name, parent.name, paths])
	return null
