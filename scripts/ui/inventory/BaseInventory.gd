# scripts/ui/inventory/BaseInventoryUI.gd - CORRIGÉ
class_name BaseInventoryUI
extends Control

# === PROPRIÉTÉS COMMUNES ===
var inventory
var controller
var container

@onready var slots_grid: GridContainer = $VBoxContainer/SlotsGrid
@onready var title_label: Label = $VBoxContainer/TitleLabel

const SLOT_SCENE = preload("res://scenes/click_system/ui/ClickableSlotUI.tscn")
var slots: Array[ClickableSlotUI] = []

signal ui_ready()

# === MÉTHODES DE BASE (À OVERRIDE) ===

func get_grid_columns() -> int:
	return 9  # Par défaut

func get_max_slots() -> int:
	return inventory.size if inventory else 45

func should_show_title() -> bool:
	return true

func get_slot_size() -> Vector2:
	return Vector2(64, 64)

# === SETUP COMMUN ===

func _ready():
	print("📦 %s ready" % get_script().get_global_name())
	# CORRECTION: Rechercher slots_grid si @onready a échoué
	_find_slots_grid()

func _find_slots_grid():
	"""Trouve le GridContainer même si @onready a échoué"""
	if not slots_grid:
		# Essayer différents chemins possibles
		slots_grid = get_node_or_null("VBoxContainer/SlotsGrid")
		if not slots_grid:
			slots_grid = get_node_or_null("HotbarGrid/GridContainer")
		if not slots_grid:
			slots_grid = get_node_or_null("SlotsGrid")
		if not slots_grid:
			slots_grid = get_node_or_null("GridContainer")
	
	if not slots_grid:
		print("❌ GridContainer introuvable dans %s" % get_script().get_global_name())
	else:
		print("✅ GridContainer trouvé: %s" % slots_grid.get_path())

func setup_with_clickable_container(clickable_container):
	"""Setup commun pour tous les types d'inventaire"""
	if not _validate_container(clickable_container):
		return
	
	container = clickable_container
	inventory = container.get_inventory()
	controller = container.get_controller()
	
	_setup_ui()
	_create_slots()
	_connect_signals()
	
	ui_ready.emit()
	print("✅ %s configuré" % get_script().get_global_name())

func _validate_container(clickable_container) -> bool:
	"""Validation du container"""
	if not clickable_container:
		print("❌ ClickableContainer invalide")
		return false
	
	if not clickable_container.has_method("get_inventory"):
		print("❌ Méthode get_inventory() manquante")
		return false
	
	if not clickable_container.has_method("get_controller"):
		print("❌ Méthode get_controller() manquante")
		return false
	
	return true

# === CONFIGURATION UI ===

func _setup_ui():
	"""Configure l'interface - peut être overridée"""
	# CORRECTION: Re-chercher slots_grid au cas où
	_find_slots_grid()
	
	if not slots_grid:
		print("❌ SlotsGrid introuvable")
		return
	
	slots_grid.columns = get_grid_columns()
	
	# CORRECTION: Mettre à jour le titre avec le bon nom
	_update_title()

func _update_title():
	"""Met à jour le titre avec le nom de l'inventaire"""
	if not title_label:
		title_label = get_node_or_null("VBoxContainer/TitleLabel")
	
	if title_label and inventory and should_show_title():
		title_label.text = inventory.name.to_upper()
		title_label.visible = true
		print("📝 Titre mis à jour: '%s'" % inventory.name)
	elif title_label:
		title_label.visible = false

# === NOUVELLE MÉTHODE POUR METTRE À JOUR LE NOM ===

func update_inventory_name():
	"""Met à jour le nom affiché - appelée par ClickableContainer"""
	_update_title()

# === GESTION DES SLOTS ===

func _create_slots():
	"""Crée tous les slots"""
	if not inventory or not slots_grid:
		print("❌ Impossible de créer les slots: inventory=%s, slots_grid=%s" % [inventory != null, slots_grid != null])
		return
	
	_clear_slots()
	
	var max_slots = get_max_slots()
	print("🔧 Création de %d slots" % max_slots)
	
	for i in range(max_slots):
		var slot = _create_slot(i)
		if slot:
			slots_grid.add_child(slot)
			slots.append(slot)
	
	print("✅ %d slots créés" % slots.size())
	call_deferred("refresh_ui")

func _create_slot(index: int) -> ClickableSlotUI:
	"""Crée un slot individuel"""
	if not SLOT_SCENE:
		return null
	
	var slot = SLOT_SCENE.instantiate() as ClickableSlotUI
	if not slot:
		return null
	
	slot.set_slot_index(index)
	slot.custom_minimum_size = get_slot_size()
	
	if slot.has_signal("slot_clicked"):
		slot.slot_clicked.connect(_on_slot_clicked)
	
	return slot

func _clear_slots():
	"""Supprime tous les slots existants"""
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	if slots_grid:
		for child in slots_grid.get_children():
			child.queue_free()

# === SIGNAUX ===

func _connect_signals():
	"""Connecte les signaux nécessaires"""
	if inventory and not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic commun"""
	if not controller:
		return

	var slot_data = controller.get_slot_info(slot_index)
	var container_id = container.get_container_id() if container else "unknown"

	var click_type = _get_click_type(mouse_event)
	var context = ClickContext.create_slot_interaction(click_type, slot_index, container_id, slot_data)

	Events.instance.slot_clicked.emit(context)

func _get_click_type(event: InputEventMouseButton) -> ClickContext.ClickType:
	"""Convertit l'événement souris en type de clic"""
	if event.button_index == MOUSE_BUTTON_RIGHT:
		return ClickContext.ClickType.SIMPLE_RIGHT_CLICK
	return ClickContext.ClickType.SIMPLE_LEFT_CLICK

# === RAFRAÎCHISSEMENT ===

func refresh_ui():
	"""Met à jour l'affichage de tous les slots"""
	if not controller or slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if slot and is_instance_valid(slot):
			var slot_data = controller.get_slot_info(i)
			slot.update_slot(slot_data)

func _on_inventory_changed():
	"""Callback quand l'inventaire change"""
	call_deferred("refresh_ui")

# === MÉTHODES VIRTUELLES POUR AFFICHAGE ===

func show_ui():
	"""À override dans les classes filles"""
	visible = true

func hide_ui():
	"""À override dans les classes filles"""
	visible = false

# === DEBUG ===

func debug_info():
	"""Affiche les infos de debug"""
	print("\n📦 %s Debug:" % get_script().get_global_name())
	print("   - Container: %s" % (container.get_container_id() if container else "none"))
	print("   - Inventory: %s" % ("ok" if inventory else "missing"))
	print("   - Controller: %s" % ("ok" if controller else "missing"))
	print("   - Slots: %d" % slots.size())
	print("   - Visible: %s" % visible)
