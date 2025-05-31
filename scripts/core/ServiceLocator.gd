class_name ServiceLocator
extends Node

static var instance: ServiceLocator
var _services: Dictionary = {}

func _init():
	if instance == null:
		instance = self
		print("🔧 ServiceLocator initialisé")

# === ENREGISTREMENT ===
static func register(service_name: String, service: Node):
	if instance:
		instance._services[service_name] = service
		print("✅ Service: %s" % service_name)

static func get_service(service_name: String):
	if instance:
		return instance._services.get(service_name)
	return null

# === SERVICES TYPÉS ===
static func inventory() -> InventorySystem:
	return get_service("inventory") as InventorySystem

static func audio() -> AudioManager:
	return get_service("audio") as AudioManager

static func game() -> GameManager:
	return get_service("game") as GameManager
