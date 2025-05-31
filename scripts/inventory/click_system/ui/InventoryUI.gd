# scripts/inventory/click_system/ui/InventoryUI.gd
class_name InventoryUI
extends Control

# === RÉFÉRENCES ===
var inventory # Pas de typage pour éviter les problèmes de référence circulaire
var controller # Pas de typage pour éviter les problèmes de référence circulaire  
var container # Pas de typage pour éviter les problèmes de référence circulaire

# === UI COMPONENTS ===
@onready var slots_grid: GridContainer = $VBoxContainer/SlotsGrid
@onready var title_label: Label = $VBoxContainer/TitleLabel

# === CONFIGURATION ===
const SLOT_SCENE = preload("res://scenes/click_system/ui/ClickableSlotUI.tscn")
var slots: Array[ClickableSlotUI] = []

func _ready():
	print("📦 InventoryUI ready - en attente de setup")

# === SETUP METHODS ===

func setup_with_clickable_container(clickable_container):
	"""Setup avec un ClickableContainer complet"""
	if not clickable_container:
		print("❌ ClickableContainer invalide")
		return
	
	container = clickable_container
	
	# CORRECTION: Vérifier que l'inventaire existe avec typage dynamique
	if container.has_method("get_inventory"):
		inventory = container.get_inventory()
		if not inventory:
			print("❌ Inventaire introuvable dans le container")
			return
	else:
		print("❌ Méthode get_inventory() manquante")
		return
	
	if container.has_method("get_controller"):
		controller = container.get_controller()
		if not controller:
			print("❌ Controller introuvable dans le container")
			return
	else:
		print("❌ Méthode get_controller() manquante")
		return
	
	# Setup de l'UI
	_setup_ui()
	_create_slots()
	_connect_signals()
	
	print("✅ InventoryUI configuré avec container: %s" % container.get_container_id())

func setup_inventory(inv: Inventory, ctrl: ClickableInventoryController):
	"""Setup direct avec inventaire et controller"""
	if not inv or not ctrl:
		print("❌ Inventaire ou controller invalide")
		return
	
	inventory = inv
	controller = ctrl
	
	_setup_ui()
	_create_slots()
	_connect_signals()
	
	print("✅ InventoryUI configuré directement")

func _setup_ui():
	"""Configure l'interface utilisateur"""
	if not slots_grid:
		print("❌ SlotsGrid introuvable")
		return
	
	# Configuration de la grille
	slots_grid.columns = Constants.GRID_COLUMNS
	
	# Titre
	if title_label and inventory:
		title_label.text = inventory.name.to_upper()

func _create_slots():
	"""Crée tous les slots de l'inventaire"""
	if not inventory or not slots_grid:
		print("❌ Impossible de créer les slots")
		return
	
	# Nettoyer les slots existants
	_clear_slots()
	
	# Créer les nouveaux slots
	for i in range(inventory.size):
		var slot = _create_slot(i)
		if slot:
			slots_grid.add_child(slot)
			slots.append(slot)
	
	print("✅ %d slots créés" % slots.size)
	
	# Rafraîchir l'affichage
	call_deferred("refresh_ui")

func _create_slot(index: int) -> ClickableSlotUI:
	"""Crée un slot individuel"""
	if not SLOT_SCENE:
		print("❌ Scene de slot introuvable")
		return null
	
	var slot = SLOT_SCENE.instantiate() as ClickableSlotUI
	if not slot:
		print("❌ Impossible d'instancier le slot %d" % index)
		return null
	
	# Configuration du slot
	slot.set_slot_index(index)
	slot.custom_minimum_size = Vector2(Constants.SLOT_SIZE, Constants.SLOT_SIZE)
	
	# Connecter le signal de clic
	if slot.has_signal("slot_clicked"):
		slot.slot_clicked.connect(_on_slot_clicked)
	
	return slot

func _clear_slots():
	"""Supprime tous les slots existants"""
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Nettoyer la grille
	if slots_grid:
		for child in slots_grid.get_children():
			child.queue_free()

func _connect_signals():
	"""Connecte les signaux nécessaires"""
	if inventory and not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

# === GESTION DES CLICS ===

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic unifié"""
	if not controller:
		print("❌ Pas de controller pour gérer le clic")
		return
	
	print("🎯 Clic UI: slot %d, bouton %d" % [slot_index, mouse_event.button_index])
	
	# Récupérer les données du slot
	var slot_data = controller.get_slot_info(slot_index)
	
	# Trouver l'intégrateur dans la hiérarchie
	var integrator = _find_click_integrator()
	if integrator:
		var container_id = container.get_container_id() if container else "unknown"
		integrator._on_slot_clicked(slot_index, mouse_event, container_id)
	else:
		print("❌ Click integrator introuvable")

func _find_click_integrator() -> ClickSystemIntegrator:
	"""Trouve l'intégrateur de clic dans la hiérarchie"""
	var current = get_parent()
	
	while current:
		# Chercher un ClickSystemIntegrator
		for child in current.get_children():
			if child is ClickSystemIntegrator:
				return child
		
		# Chercher dans les nœuds frères (cas InventorySystem)
		if current.has_method("get_click_integrator"):
			return current.get_click_integrator()
		
		current = current.get_parent()
	
	return null

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

# === ANIMATION (optionnel) ===

func show_animated():
	"""Affiche l'UI avec animation"""
	visible = true
	
	# Animation simple
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_animated():
	"""Cache l'UI avec animation"""
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)

# === DEBUG ===

func debug_info():
	"""Affiche les infos de debug"""
	print("\n📦 InventoryUI Debug:")
	print("   - Container: %s" % (container.get_container_id() if container else "none"))
	print("   - Inventory: %s" % ("ok" if inventory else "missing"))
	print("   - Controller: %s" % ("ok" if controller else "missing"))
	print("   - Slots: %d" % slots.size())
	print("   - Visible: %s" % visible)
