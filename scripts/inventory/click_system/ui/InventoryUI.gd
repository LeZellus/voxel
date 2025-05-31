# scripts/inventory/click_system/ui/InventoryUI.gd
class_name InventoryUI
extends Control

# === RÉFÉRENCES ===
var inventory
var controller  
var container

# === UI COMPONENTS ===
@onready var slots_grid: GridContainer = $VBoxContainer/SlotsGrid
@onready var title_label: Label = $VBoxContainer/TitleLabel

# === CONFIGURATION ===
const SLOT_SCENE = preload("res://scenes/click_system/ui/ClickableSlotUI.tscn")
var slots: Array[ClickableSlotUI] = []

# === ANIMATION ===
var animation_tween: Tween
var original_position: Vector2
var is_animating: bool = false

# === PARAMÈTRES D'ANIMATION ===
const SLIDE_DURATION: float = 0.4
const SLIDE_EASE: Tween.EaseType = Tween.EASE_OUT
const SLIDE_TRANS: Tween.TransitionType = Tween.TRANS_BACK
const FADE_DURATION: float = 0.3

func _ready():
	print("📦 InventoryUI ready - en attente de setup")
	_setup_animations()

func _setup_animations():
	"""Configure les propriétés d'animation"""
	# Sauvegarder la position originale
	original_position = position
	
	# Position de départ (hors écran vers le bas)
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position = Vector2(original_position.x, viewport_size.y)
	
	# Démarrer invisible et en bas
	position = start_position
	modulate.a = 0.0
	visible = false

# === SETUP METHODS ===

func setup_with_clickable_container(clickable_container):
	"""Setup avec un ClickableContainer complet"""
	if not clickable_container:
		print("❌ ClickableContainer invalide")
		return
	
	container = clickable_container
	
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
	
	slots_grid.columns = Constants.GRID_COLUMNS
	
	if title_label and inventory:
		title_label.text = inventory.name.to_upper()

func _create_slots():
	"""Crée tous les slots de l'inventaire"""
	if not inventory or not slots_grid:
		print("❌ Impossible de créer les slots")
		return
	
	_clear_slots()
	
	for i in range(inventory.size):
		var slot = _create_slot(i)
		if slot:
			slots_grid.add_child(slot)
			slots.append(slot)
	
	print("✅ %d slots créés" % slots.size)
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
	
	slot.set_slot_index(index)
	slot.custom_minimum_size = Vector2(Constants.SLOT_SIZE, Constants.SLOT_SIZE)
	
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

func _connect_signals():
	"""Connecte les signaux nécessaires"""
	if inventory and not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)

# === ANIMATIONS AMÉLIORÉES ===

func show_animated():
	"""Affiche l'UI avec animation de slide depuis le bas"""
	if is_animating:
		return
	
	print("🎬 Animation d'ouverture de l'inventaire")
	is_animating = true
	
	# Assurer que l'UI est visible
	visible = true
	
	# Nettoyer l'ancien tween
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)  # Permet les animations simultanées
	
	# Position de départ (hors écran)
	var viewport_size = get_viewport().get_visible_rect().size
	var start_position = Vector2(original_position.x, viewport_size.y)
	position = start_position
	modulate.a = 0.0
	
	# Animation de slide vers le haut
	animation_tween.tween_property(
		self, 
		"position", 
		original_position, 
		SLIDE_DURATION
	).set_ease(SLIDE_EASE).set_trans(SLIDE_TRANS)
	
	# Animation de fade in
	animation_tween.tween_property(
		self, 
		"modulate:a", 
		1.0, 
		FADE_DURATION
	).set_ease(Tween.EASE_OUT)
	
	# Animation des slots (effet cascade)
	_animate_slots_cascade_in()
	
	# Callback de fin
	animation_tween.tween_callback(_on_show_animation_finished)

func hide_animated():
	"""Cache l'UI avec animation de slide vers le bas (identique à l'ouverture)"""
	if is_animating:
		return
	
	print("🎬 Animation de fermeture de l'inventaire")
	is_animating = true
	
	if animation_tween:
		animation_tween.kill()
	
	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	
	# Position de fin (hors écran vers le bas)
	var viewport_size = get_viewport().get_visible_rect().size
	var end_position = Vector2(original_position.x, viewport_size.y)
	
	# Animation de slide vers le bas (MÊMES paramètres que l'ouverture)
	animation_tween.tween_property(
		self, 
		"position", 
		end_position, 
		SLIDE_DURATION  # Même durée que l'ouverture
	).set_ease(Tween.EASE_IN).set_trans(SLIDE_TRANS)  # Même transition
	
	# Animation de fade out (MÊMES paramètres)
	animation_tween.tween_property(
		self, 
		"modulate:a", 
		0.0, 
		FADE_DURATION  # Même durée de fade
	).set_ease(Tween.EASE_IN)
	
	# Animation des slots (effet cascade identique mais inverse)
	_animate_slots_cascade_out()
	
	# Callback de fin
	animation_tween.tween_callback(_on_hide_animation_finished)

func _animate_slots_cascade_in():
	"""Animation en cascade des slots à l'ouverture"""
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot or not is_instance_valid(slot):
			continue
		
		# Position et alpha de départ
		slot.modulate.a = 0.0
		slot.scale = Vector2(0.8, 0.8)
		
		# Délai basé sur la position (ligne par ligne)
		var row = i / Constants.GRID_COLUMNS
		var delay = row * 0.03  # 30ms par ligne
		
		# Utiliser call_deferred avec un timer pour le délai
		if delay > 0:
			get_tree().create_timer(delay).timeout.connect(_animate_single_slot_in.bind(slot))
		else:
			_animate_single_slot_in(slot)

func _animate_single_slot_in(slot: ClickableSlotUI):
	"""Anime un slot individuel à l'ouverture"""
	if not slot or not is_instance_valid(slot):
		return
	
	var slot_tween = create_tween()
	slot_tween.set_parallel(true)
	
	slot_tween.tween_property(slot, "modulate:a", 1.0, 0.2)
	slot_tween.tween_property(slot, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_slots_cascade_out():
	"""Animation en cascade des slots à la fermeture (identique à l'ouverture mais inverse)"""
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot or not is_instance_valid(slot):
			continue
		
		# Délai inverse : les dernières lignes disparaissent en premier
		var row = i / Constants.GRID_COLUMNS
		var max_rows = (slots.size() - 1) / Constants.GRID_COLUMNS
		var delay = (max_rows - row) * 0.03  # MÊME délai que l'ouverture
		
		# Utiliser call_deferred avec un timer pour le délai
		if delay > 0:
			get_tree().create_timer(delay).timeout.connect(_animate_single_slot_out.bind(slot))
		else:
			_animate_single_slot_out(slot)

func _animate_single_slot_out(slot: ClickableSlotUI):
	"""Anime un slot individuel à la fermeture (effet symétrique)"""
	if not slot or not is_instance_valid(slot):
		return
	
	var slot_tween = create_tween()
	slot_tween.set_parallel(true)
	
	# MÊMES durées que l'ouverture mais vers les valeurs de départ
	slot_tween.tween_property(slot, "modulate:a", 0.0, 0.2)  # Même durée
	slot_tween.tween_property(slot, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)  # Même transition mais EASE_IN

func _on_show_animation_finished():
	"""Callback de fin d'animation d'ouverture"""
	is_animating = false
	print("✅ Animation d'ouverture terminée")

func _on_hide_animation_finished():
	"""Callback de fin d'animation de fermeture"""
	visible = false
	is_animating = false
	print("✅ Animation de fermeture terminée")

# === GESTION DES CLICS ===

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic unifié"""
	if not controller:
		print("❌ Pas de controller pour gérer le clic")
		return
	
	print("🎯 Clic UI: slot %d, bouton %d" % [slot_index, mouse_event.button_index])
	
	var slot_data = controller.get_slot_info(slot_index)
	
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
		for child in current.get_children():
			if child is ClickSystemIntegrator:
				return child
		
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

# === UTILITAIRES ===

func force_update_position():
	"""Force la mise à jour de la position originale (utile si la fenêtre change)"""
	if not visible:
		original_position = position

# === DEBUG ===

func debug_info():
	"""Affiche les infos de debug"""
	print("\n📦 InventoryUI Debug:")
	print("   - Container: %s" % (container.get_container_id() if container else "none"))
	print("   - Inventory: %s" % ("ok" if inventory else "missing"))
	print("   - Controller: %s" % ("ok" if controller else "missing"))
	print("   - Slots: %d" % slots.size())
	print("   - Visible: %s" % visible)
	print("   - Is animating: %s" % is_animating)
