# scripts/ui/inventory/BaseInventoryUI.gd - VERSION AVEC RAFRAÎCHISSEMENT FORCÉ
class_name BaseInventoryUI
extends Control

var inventory
var controller  
var container

var slots_grid: GridContainer
var title_label: Label
var slots: Array[ClickableSlotUI] = []

const SLOT_SCENE = preload("res://scenes/click_system/ui/ClickableSlotUI.tscn")

# Méthodes virtuelles
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
	"""Création des slots"""
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
		
		# CONNEXION DIRECTE AU SYSTÈME D'ÉVÉNEMENTS
		slot.slot_clicked.connect(_on_slot_clicked)
		
		slots_grid.add_child(slot)
		slots.append(slot)

func _connect_inventory_signals():
	"""Connexion des signaux - AMÉLIORÉE"""
	if not inventory:
		return
		
	# Connexion du signal principal
	if not inventory.inventory_changed.is_connected(refresh_ui):
		inventory.inventory_changed.connect(refresh_ui)
		print("✅ Signal inventory_changed connecté")
	
	# NOUVEAU: Connexion aux slots individuels pour plus de réactivité
	for i in range(inventory.size):
		var slot = inventory.get_slot(i)
		if slot and not slot.slot_changed.is_connected(_on_individual_slot_changed):
			slot.slot_changed.connect(_on_individual_slot_changed.bind(i))

func _on_individual_slot_changed(slot_index: int):
	"""NOUVEAU: Réaction immédiate aux changements de slot individuel"""
	print("🔄 Slot %d changé - refresh immédiat" % slot_index)
	
	# Mettre à jour ce slot spécifiquement
	if slot_index < slots.size():
		var slot_ui = slots[slot_index]
		if slot_ui and controller:
			var slot_data = controller.get_slot_info(slot_index)
			slot_ui.update_slot(slot_data)
			print("  ✅ Slot UI %d mis à jour individuellement" % slot_index)

func refresh_ui():
	"""Rafraîchissement standard - AMÉLIORÉ"""
	print("🔄 BaseInventoryUI.refresh_ui() appelé pour %s" % (inventory.name if inventory else "inconnu"))
	
	if not controller:
		print("  ❌ Controller manquant")
		return
	
	# NOUVEAU: Validation des slots UI
	if slots.size() != get_slot_count():
		print("  ⚠️ Nombre de slots UI incorrect (%d vs %d) - recréation" % [slots.size(), get_slot_count()])
		_create_all_slots()
		return
	
	# Rafraîchir chaque slot
	var updated_count = 0
	for i in range(slots.size()):
		var slot = slots[i]
		if slot and is_instance_valid(slot):
			var slot_data = controller.get_slot_info(i)
			
			# DEBUG détaillé
			if not slot_data.get("is_empty", true):
				print("  📦 Slot %d: %s x%d" % [i, slot_data.get("item_name", "?"), slot_data.get("quantity", 0)])
			
			slot.update_slot(slot_data)
			updated_count += 1
		else:
			print("  ❌ Slot UI %d invalide" % i)
	
	print("  ✅ %d slots UI mis à jour" % updated_count)
	
	# NOUVEAU: Forcer un update visuel supplémentaire
	call_deferred("_force_visual_update")

func _force_visual_update():
	"""NOUVEAU: Force une mise à jour visuelle supplémentaire"""
	for slot in slots:
		if slot and is_instance_valid(slot):
			# Forcer le redraw des composants visuels
			if slot.item_icon:
				slot.item_icon.queue_redraw()
			if slot.quantity_label:
				slot.quantity_label.queue_redraw()

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic - ÉMISSION DIRECTE VIA EVENTS"""
	if not controller or not container:
		print("❌ Controller ou container manquant")
		return

	var slot_data = controller.get_slot_info(slot_index)
	var click_type = ClickContext.ClickType.SIMPLE_RIGHT_CLICK if mouse_event.button_index == MOUSE_BUTTON_RIGHT else ClickContext.ClickType.SIMPLE_LEFT_CLICK
	
	var context = ClickContext.create_slot_interaction(
		click_type, 
		slot_index, 
		container.get_container_id(), 
		slot_data
	)
	
	# ÉMISSION DIRECTE VIA EVENTS
	if Events.instance:
		Events.instance.slot_clicked.emit(context)
	else:
		print("❌ Events.instance introuvable")

# === NOUVELLE MÉTHODE DE DEBUG ===

func debug_ui_state():
	"""Debug l'état de l'UI"""
	print("\n🔍 DEBUG BaseInventoryUI '%s':" % (inventory.name if inventory else "?"))
	print("   - Slots UI créés: %d" % slots.size())
	print("   - Slots inventaire: %d" % (inventory.size if inventory else 0))
	print("   - Controller: %s" % ("✅" if controller else "❌"))
	print("   - Container: %s" % ("✅" if container else "❌"))
	
	if controller and inventory:
		print("   - Contenu inventaire:")
		for i in range(min(5, inventory.size)):  # Montrer les 5 premiers
			var slot_data = controller.get_slot_info(i)
			if not slot_data.get("is_empty", true):
				print("     Slot %d: %s x%d" % [i, slot_data.get("item_name", "?"), slot_data.get("quantity", 0)])
