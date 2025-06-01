# scripts/ui/inventory/BaseInventoryUI.gd - AVEC SUPPORT NOUVEAU SYSTÈME
class_name BaseInventoryUI
extends Control

var inventory
var controller  
var container

var slots_grid: GridContainer
var title_label: Label
var slots: Array[ClickableSlotUI] = []

const SLOT_SCENE = preload("res://scenes/click_system/ui/ClickableSlotUI.tscn")

# Méthodes virtuelles (inchangées)
func get_columns() -> int: return Constants.GRID_COLUMNS
func get_slot_count() -> int: return inventory.size if inventory else Constants.MAIN_INVENTORY_SLOTS
func has_title() -> bool: return true
func get_slot_size() -> Vector2: return Constants.get_slot_size()

func _ready():
	_find_ui_components()

func _find_ui_components():
	"""Trouve les composants UI"""
	slots_grid = UIHelper.find_slots_grid(self)
	
	var title_paths: Array[String] = ["VBoxContainer/TitleLabel", "TitleLabel"]
	title_label = UIHelper.find_node_safe(self, title_paths) as Label
	
	if not ValidationUtils.validate_ui_component(slots_grid, "GridContainer", name):
		return

func setup_with_clickable_container(clickable_container):
	"""Setup principal"""
	var required_methods = ["get_inventory", "get_controller", "get_container_id"]
	if not ValidationUtils.validate_container_interface(clickable_container, required_methods, name):
		return
		
	container = clickable_container
	inventory = container.get_inventory()
	controller = container.get_controller()
	
	_configure_ui()
	_create_all_slots()
	_connect_inventory_signals()

func _configure_ui():
	"""Configuration UI"""
	if slots_grid:
		slots_grid.columns = get_columns()
	
	if title_label and has_title() and inventory:
		title_label.text = inventory.name.to_upper()
		title_label.visible = true

func _create_all_slots():
	"""Création des slots - MODIFIÉE POUR NOUVEAU SYSTÈME"""
	if not slots_grid or not SLOT_SCENE:
		return
		
	# Clear existing
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Create new
	for i in range(get_slot_count()):
		var slot = SLOT_SCENE.instantiate() as ClickableSlotUI
		slot.set_slot_index(i)
		slot.custom_minimum_size = get_slot_size()
		
		# NOUVEAU : Connexion au nouveau signal d'action avancée
		slot.slot_action_detected.connect(_on_slot_action_detected)
		
		slots_grid.add_child(slot)
		slots.append(slot)

func _connect_inventory_signals():
	"""Connexion des signaux - inchangée"""
	if not inventory:
		return
		
	if not inventory.inventory_changed.is_connected(refresh_ui):
		inventory.inventory_changed.connect(refresh_ui)
		print("✅ Signal inventory_changed connecté")
	
	for i in range(inventory.size):
		var slot = inventory.get_slot(i)
		if slot and not slot.slot_changed.is_connected(_on_individual_slot_changed):
			slot.slot_changed.connect(_on_individual_slot_changed.bind(i))

func _on_individual_slot_changed(slot_index: int):
	"""Réaction immédiate aux changements de slot individuel"""
	print("🔄 Slot %d changé - refresh immédiat" % slot_index)
	
	if slot_index < slots.size():
		var slot_ui = slots[slot_index]
		if slot_ui and controller:
			var slot_data = controller.get_slot_info(slot_index)
			slot_ui.update_slot(slot_data)

# === NOUVEAU : GESTIONNAIRE D'ACTIONS AVANCÉES ===

func _on_slot_action_detected(slot_index: int, action_type: InputStateManager.ActionType, context: Dictionary):
	"""NOUVEAU : Gestionnaire pour les actions avancées détectées"""
	if not controller or not container:
		print("❌ Controller ou container manquant")
		return

	# Enrichir le contexte avec nos données
	var enriched_context = context.duplicate()
	enriched_context["container_id"] = container.get_container_id()
	enriched_context["slot_data"] = controller.get_slot_info(slot_index)
	
	# Créer le ClickContext étendu
	var click_context = _create_extended_click_context(slot_index, action_type, enriched_context)
	
	# DEBUG
	print("🎮 Action détectée: %s sur slot %d" % [
		InputStateManager.ActionType.keys()[action_type], 
		slot_index
	])
	
	# Émettre via Events pour que ClickSystemIntegrator prenne le relai
	if Events.instance:
		Events.instance.slot_clicked.emit(click_context)
	else:
		print("❌ Events.instance introuvable")

func _create_extended_click_context(slot_index: int, action_type: InputStateManager.ActionType, context: Dictionary) -> ClickContext:
	"""NOUVEAU : Crée un ClickContext étendu à partir du nouveau système"""
	
	# Mapper les types InputStateManager vers ClickContext
	var mapped_action = _map_action_type(action_type)
	
	# Créer le contexte étendu
	var click_context = ClickContext.create_advanced_interaction(
		mapped_action,
		slot_index,
		context.get("container_id", ""),
		context.get("slot_data", {}),
		context.get("modifiers", {}),
		_extract_extra_data(action_type, context)
	)
	
	click_context.mouse_position = context.get("mouse_position", Vector2.ZERO)
	
	return click_context

func _map_action_type(action_type: InputStateManager.ActionType) -> ClickContext.ActionType:
	"""NOUVEAU : Mappe les types d'action entre les deux systèmes"""
	match action_type:
		InputStateManager.ActionType.SIMPLE_LEFT_CLICK:
			return ClickContext.ActionType.SIMPLE_LEFT_CLICK
		InputStateManager.ActionType.SIMPLE_RIGHT_CLICK:
			return ClickContext.ActionType.SIMPLE_RIGHT_CLICK
		InputStateManager.ActionType.MIDDLE_CLICK:
			return ClickContext.ActionType.MIDDLE_CLICK
		InputStateManager.ActionType.DOUBLE_LEFT_CLICK:
			return ClickContext.ActionType.DOUBLE_LEFT_CLICK
		InputStateManager.ActionType.SHIFT_LEFT_CLICK:
			return ClickContext.ActionType.SHIFT_LEFT_CLICK
		InputStateManager.ActionType.LEFT_DRAG_START:
			return ClickContext.ActionType.LEFT_DRAG_START
		InputStateManager.ActionType.LEFT_DRAG_CONTINUE:
			return ClickContext.ActionType.LEFT_DRAG_CONTINUE
		InputStateManager.ActionType.LEFT_DRAG_END:
			return ClickContext.ActionType.LEFT_DRAG_END
		InputStateManager.ActionType.RIGHT_HOLD_START:
			return ClickContext.ActionType.RIGHT_HOLD_START
		InputStateManager.ActionType.RIGHT_HOLD_CONTINUE:
			return ClickContext.ActionType.RIGHT_HOLD_CONTINUE
		InputStateManager.ActionType.RIGHT_HOLD_END:
			return ClickContext.ActionType.RIGHT_HOLD_END
		_:
			return ClickContext.ActionType.SIMPLE_LEFT_CLICK

func _extract_extra_data(action_type: InputStateManager.ActionType, context: Dictionary) -> Dictionary:
	"""NOUVEAU : Extrait les données supplémentaires selon le type d'action"""
	var extra_data = {}
	
	match action_type:
		InputStateManager.ActionType.LEFT_DRAG_START, InputStateManager.ActionType.LEFT_DRAG_CONTINUE, InputStateManager.ActionType.LEFT_DRAG_END:
			extra_data = {
				"start_position": context.get("mouse_position", Vector2.ZERO),
				"current_position": context.get("mouse_position", Vector2.ZERO),
				"distance": 0.0,  # Sera calculé par l'action
				"slots_visited": []  # Se remplit au fur et à mesure
			}
		
		InputStateManager.ActionType.RIGHT_HOLD_START, InputStateManager.ActionType.RIGHT_HOLD_CONTINUE, InputStateManager.ActionType.RIGHT_HOLD_END:
			extra_data = {
				"start_time": Time.get_unix_time_from_system(),
				"duration": 0.0,  # Sera calculé par l'action
				"slots_visited": []
			}
	
	return extra_data

# === MÉTHODES EXISTANTES (inchangées) ===

func refresh_ui():
	"""Rafraîchissement standard"""
	print("🔄 BaseInventoryUI.refresh_ui() appelé pour %s" % (inventory.name if inventory else "inconnu"))
	
	if not controller:
		print("  ❌ Controller manquant")
		return
	
	if slots.size() != get_slot_count():
		print("  ⚠️ Nombre de slots UI incorrect (%d vs %d) - recréation" % [slots.size(), get_slot_count()])
		_create_all_slots()
		return
	
	var updated_count = 0
	for i in range(slots.size()):
		var slot = slots[i]
		if slot and is_instance_valid(slot):
			var slot_data = controller.get_slot_info(i)
			
			if not slot_data.get("is_empty", true):
				print("  📦 Slot %d: %s x%d" % [i, slot_data.get("item_name", "?"), slot_data.get("quantity", 0)])
			
			slot.update_slot(slot_data)
			updated_count += 1
		else:
			print("  ❌ Slot UI %d invalide" % i)
	
	print("  ✅ %d slots UI mis à jour" % updated_count)
	call_deferred("_force_visual_update")

func _force_visual_update():
	"""Force une mise à jour visuelle supplémentaire"""
	for slot in slots:
		if slot and is_instance_valid(slot):
			if slot.item_icon:
				slot.item_icon.queue_redraw()
			if slot.quantity_label:
				slot.quantity_label.queue_redraw()

# === DEBUG ÉTENDU ===

func debug_ui_state():
	"""Debug l'état de l'UI"""
	print("\n🔍 DEBUG BaseInventoryUI '%s':" % (inventory.name if inventory else "?"))
	print("   - Slots UI créés: %d" % slots.size())
	print("   - Slots inventaire: %d" % (inventory.size if inventory else 0))
	print("   - Controller: %s" % ("✅" if controller else "❌"))
	print("   - Container: %s" % ("✅" if container else "❌"))
	
	if controller and inventory:
		print("   - Contenu inventaire:")
		for i in range(min(5, inventory.size)):
			var slot_data = controller.get_slot_info(i)
			if not slot_data.get("is_empty", true):
				print("     Slot %d: %s x%d" % [i, slot_data.get("item_name", "?"), slot_data.get("quantity", 0)])

func debug_input_states():
	"""NOUVEAU : Debug des états d'input de tous les slots"""
	print("\n🎮 DEBUG États d'input des slots:")
	for i in range(min(5, slots.size())):
		var slot = slots[i]
		if slot:
			print("   Slot[%d]: %s" % [i, slot.get_current_action_state()])
