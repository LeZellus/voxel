# scripts/inventory/click_system/containers/ClickSystemIntegrator.gd - VERSION REFACTORISÉE
class_name ClickSystemIntegrator
extends Node

var click_system: ClickSystemManager
var registered_uis: Dictionary = {}
var selected_slot_info: Dictionary = {}

func _ready():
	_setup_click_system()
	
	if Events.instance:
		Events.instance.slot_clicked.connect(_handle_slot_click_via_events)
		print("🔗 ClickSystemIntegrator connecté aux Events")
	else:
		print("❌ Events non disponible")

func _setup_click_system():
	"""Configure le gestionnaire de clic"""
	click_system = ClickSystemManager.new()
	add_child(click_system)
	
	print("✅ ClickSystemIntegrator configuré (refactorisé)")
	
func _handle_slot_click_via_events(context: ClickContext):
	"""Nouveau gestionnaire via Events"""
	print("🎯 Clic reçu via Events: slot %d, container %s" % [context.source_slot_index, context.source_container_id])
	
	_handle_visual_selection(context)
	# Traiter le clic (utilise ton code existant)
	var success = click_system.action_registry.execute(context)
	
	if success:
	# Rafraîchir les UIs
		call_deferred("_refresh_all_uis")

func _refresh_all_uis():
	"""Rafraîchit toutes les UIs enregistrées"""
	for container_id in registered_uis.keys():
		var ui = registered_uis[container_id]
		if ui and ui.has_method("refresh_ui"):
			ui.refresh_ui()

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

func _handle_visual_selection(context: ClickContext):
	"""Gère la sélection visuelle des slots"""
	
	# Si on a déjà un slot sélectionné
	if not selected_slot_info.is_empty():
		print("🔹 Slot déjà sélectionné: %s[%d]" % [selected_slot_info.container_id, selected_slot_info.slot_index])
		
		# Si on clique sur le même slot = désélectionner
		if (context.source_slot_index == selected_slot_info.slot_index and 
			context.source_container_id == selected_slot_info.container_id):
			print("❌ Désélection du slot")
			_clear_selection()
			return
		
		# Sinon = nouveau clic = destination
		print("➡️ Destination: slot %d" % context.source_slot_index)
		_clear_selection()
		return
	
	# Nouveau clic = sélection (seulement si le slot a un item)
	if not context.source_slot_data.get("is_empty", true):
		print("📌 Sélection: slot %d" % context.source_slot_index)
		selected_slot_info = {
			"slot_index": context.source_slot_index,
			"container_id": context.source_container_id
		}
		_highlight_selected_slot()

func _highlight_selected_slot():
	"""Surligne visuellement le slot sélectionné"""
	if selected_slot_info.is_empty():
		return
	
	var ui = registered_uis.get(selected_slot_info.container_id)
	if not ui:
		return
	
	# Chercher le slot UI correspondant
	var slot_ui = _find_slot_ui(ui, selected_slot_info.slot_index)
	if slot_ui and slot_ui.has_method("set_selected"):
		slot_ui.set_selected(true)
		print("✨ Slot %d surligné" % selected_slot_info.slot_index)

func _clear_selection():
	"""Efface la sélection visuelle"""
	if selected_slot_info.is_empty():
		return
	
	var ui = registered_uis.get(selected_slot_info.container_id)
	if ui:
		var slot_ui = _find_slot_ui(ui, selected_slot_info.slot_index)
		if slot_ui and slot_ui.has_method("set_selected"):
			slot_ui.set_selected(false)
			print("🔹 Surligement effacé slot %d" % selected_slot_info.slot_index)
	
	selected_slot_info.clear()

func _find_slot_ui(ui: Control, slot_index: int) -> ClickableSlotUI:
	"""Trouve le ClickableSlotUI avec l'index donné"""
	var slots = _find_slots_in_ui(ui)
	for slot in slots:
		if slot.get_slot_index() == slot_index:
			return slot
	return null
