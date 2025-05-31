# scripts/ui/inventory/BaseInventoryUI.gd - VERSION SIMPLIFIÉE
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
func get_columns() -> int: return 9
func get_slot_count() -> int: return inventory.size if inventory else 45
func has_title() -> bool: return true
func get_slot_size() -> Vector2: return Vector2(64, 64)

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
	"""Connexion des signaux"""
	if inventory and not inventory.inventory_changed.is_connected(refresh_ui):
		inventory.inventory_changed.connect(refresh_ui)

func refresh_ui():
	"""Rafraîchissement standard"""
	if not controller:
		return
		
	for i in range(slots.size()):
		var slot = slots[i]
		if slot and is_instance_valid(slot):
			var slot_data = controller.get_slot_info(i)
			slot.update_slot(slot_data)

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
