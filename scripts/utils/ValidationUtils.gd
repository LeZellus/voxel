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
