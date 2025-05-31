# DebugHelper.gd
class_name DebugHelper

static func log_error(context: String, message: String):
	print("[ERREUR] %s: %s" % [context, message])

static func log_warning(context: String, message: String):
	print("[ATTENTION] %s: %s" % [context, message])

static func log_info(context: String, message: String):
	print("[INFO] %s: %s" % [context, message])

static func node_not_found(node_name: String, context: String):
	log_error(context, "Node '%s' introuvable" % node_name)

static func resource_not_found(resource_name: String, context: String):
	log_error(context, "Resource '%s' introuvable" % resource_name)

static func check_node(node: Node, node_name: String, context: String) -> bool:
	if node == null:
		node_not_found(node_name, context)
		return false
	return true

static func check_resource(resource: Resource, resource_name: String, context: String) -> bool:
	if resource == null:
		resource_not_found(resource_name, context)
		return false
	return true
