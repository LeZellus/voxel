# scripts/inventory/click_system/containers/ClickSystemIntegrator.gd - VERSION REFACTORISÉE
class_name ClickSystemIntegrator
extends Node

var click_system: ClickSystemManager
var registered_uis: Dictionary = {}

func _ready():
	_setup_click_system()

func _setup_click_system():
	"""Configure le gestionnaire de clic"""
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	print("✅ ClickSystemIntegrator configuré (refactorisé)")

# === ENREGISTREMENT (API IDENTIQUE) ===
func register_container(container_id: String, controller, ui: Control):
	"""Enregistre un container et son UI"""
	
	# Enregistrer le contrôleur
	click_system.register_container(container_id, controller)
	
	# Connecter l'UI si elle existe
	if ui:
		_connect_ui_signals(ui, container_id)
		registered_uis[container_id] = ui
	
	print("🔗 Container connecté au click system: %s" % container_id)

func _connect_ui_signals(ui: Control, container_id: String):
	"""Connecte les signaux d'une UI au click system"""
	
	# Chercher les slots dans l'UI
	var slots = _find_slots_in_ui(ui)
	
	for slot in slots:
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_slot_clicked.bind(container_id))

func _find_slots_in_ui(ui: Control) -> Array:
	"""Trouve tous les ClickableSlotUI dans une UI"""
	var slots = []
	_find_slots_recursive(ui, slots)
	return slots

func _find_slots_recursive(node: Node, slots: Array):
	"""Recherche récursive de ClickableSlotUI"""
	if node is ClickableSlotUI:
		slots.append(node)
	
	for child in node.get_children():
		_find_slots_recursive(child, slots)

# === GESTION DES CLICS (API IDENTIQUE) ===
func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton, container_id: String):
	"""Gestionnaire de clic unifié"""
	print("🎯 Clic détecté: slot %d, container %s, bouton %d" % [slot_index, container_id, mouse_event.button_index])
	
	# Récupérer les données du slot
	var controller = click_system.get_controller_for_container(container_id)
	if not controller:
		print("❌ Controller introuvable pour %s" % container_id)
		return
	
	var slot_data = controller.get_slot_info(slot_index)
	
	# Passer au click system
	click_system.handle_slot_click(slot_index, container_id, slot_data, mouse_event)
	
	# Rafraîchir l'UI après l'action
	call_deferred("_refresh_ui", container_id)

func _refresh_ui(container_id: String):
	"""Rafraîchit l'UI après une action"""
	var ui = registered_uis.get(container_id)
	if ui and ui.has_method("refresh_ui"):
		ui.refresh_ui()

# === DEBUG ===
func debug_system():
	print("\n🔗 ClickSystemIntegrator (refactorisé):")
	print("   - UIs enregistrées: %s" % registered_uis.keys())
	
	if click_system:
		click_system.print_debug_info()
