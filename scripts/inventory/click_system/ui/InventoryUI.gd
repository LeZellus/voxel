# scripts/inventory/click_system/ui/InventoryUI.gd - VERSION FINALE CORRIGÉE
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
const GRID_COLUMNS = 9  # Constante locale pour éviter les erreurs de référence
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
	
	# Utiliser la constante locale au lieu de Constants.GRID_COLUMNS
	slots_grid.columns = GRID_COLUMNS
	
	# CORRECTION: Appliquer le nom d'affichage et forcer la mise à jour
	if title_label and inventory:
		title_label.text = inventory.name.to_upper()
		print("📝 Titre mis à jour: '%s'" % title_label.text)

func _create_slots():
	"""Crée tous les slots de l'inventaire"""
	if not inventory or not slots_grid:
		print("❌ Impossible de créer les slots - inventory: %s, slots_grid: %s" % [inventory != null, slots_grid != null])
		return
	
	_clear_slots()
	
	print("🔧 Création de %d slots" % inventory.size)
	
	for i in range(inventory.size):
		var slot = _create_slot(i)
		if slot:
			slots_grid.add_child(slot)
			slots.append(slot)
		else:
			print("❌ Échec création slot %d" % i)
	
	# CORRECTION: Utiliser slots.size() au lieu de Constants.SLOT_SIZE
	print("✅ %d slots créés" % slots.size())
	call_deferred("refresh_ui")
	
	# CORRECTION: Remettre à jour le titre après la création des slots
	call_deferred("_update_title")

func _update_title():
	"""Met à jour le titre de l'inventaire (appelé après setup)"""
	if title_label and inventory:
		title_label.text = inventory.name.to_upper()
		print("🔄 Titre final appliqué: '%s'" % title_label.text)

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
	
	# Utiliser une taille fixe au lieu de Constants.SLOT_SIZE
	var slot_size = 64  # Constante locale
	slot.custom_minimum_size = Vector2(slot_size, slot_size)
	
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
	animation_tween.set_parallel(true)
	
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
	"""Cache l'UI avec animation de slide vers le bas"""
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
	
	# Animation de slide vers le bas
	animation_tween.tween_property(
		self, 
		"position", 
		end_position, 
		SLIDE_DURATION
	).set_ease(Tween.EASE_IN).set_trans(SLIDE_TRANS)
	
	# Animation de fade out
	animation_tween.tween_property(
		self, 
		"modulate:a", 
		0.0, 
		FADE_DURATION
	).set_ease(Tween.EASE_IN)
	
	# Animation des slots (effet cascade)
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
		var row = i / GRID_COLUMNS  # Utiliser la constante locale
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
	"""Animation en cascade des slots à la fermeture"""
	if slots.is_empty():
		return
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot or not is_instance_valid(slot):
			continue
		
		# Délai inverse : les dernières lignes disparaissent en premier
		var row = i / GRID_COLUMNS  # Utiliser la constante locale
		var max_rows = (slots.size() - 1) / GRID_COLUMNS
		var delay = (max_rows - row) * 0.03
		
		# Utiliser call_deferred avec un timer pour le délai
		if delay > 0:
			get_tree().create_timer(delay).timeout.connect(_animate_single_slot_out.bind(slot))
		else:
			_animate_single_slot_out(slot)

func _animate_single_slot_out(slot: ClickableSlotUI):
	"""Anime un slot individuel à la fermeture"""
	if not slot or not is_instance_valid(slot):
		return
	
	var slot_tween = create_tween()
	slot_tween.set_parallel(true)
	
	slot_tween.tween_property(slot, "modulate:a", 0.0, 0.2)
	slot_tween.tween_property(slot, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

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
	"""Gestionnaire de clic simplifié avec Events"""
	if not controller:
		print("❌ Pas de controller pour gérer le clic")
	return

	print("🎯 Clic UI: slot %d, bouton %d" % [slot_index, mouse_event.button_index])

	var slot_data = controller.get_slot_info(slot_index)
	var container_id = container.get_container_id() if container else "unknown"

	# Créer le contexte de clic
	var click_type = _get_click_type(mouse_event)
	var context = ClickContext.create_slot_interaction(click_type, slot_index, container_id, slot_data)

	# NOUVEAU - Émettre via Events au lieu de chercher dans la hiérarchie
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

# === UTILITAIRES ===

func force_update_position():
	"""Force la mise à jour de la position originale"""
	if not visible:
		original_position = position

# === MÉTHODE PUBLIQUE POUR FORCER LA MISE À JOUR DU TITRE ===

func update_inventory_name():
	"""Force la mise à jour du nom d'inventaire (méthode publique)"""
	if title_label and inventory:
		title_label.text = inventory.name.to_upper()
		print("🔄 Nom d'inventaire forcé: '%s'" % title_label.text)

# === DEBUG ===

func debug_info():
	"""Affiche les infos de debug"""
	print("\n📦 InventoryUI Debug:")
	print("   - Container: %s" % (container.get_container_id() if container else "none"))
	print("   - Inventory: %s" % ("ok" if inventory else "missing"))
	print("   - Inventory name: '%s'" % (inventory.name if inventory else "none"))
	print("   - Title label text: '%s'" % (title_label.text if title_label else "none"))
	print("   - Controller: %s" % ("ok" if controller else "missing"))
	print("   - Slots: %d" % slots.size())
	print("   - Visible: %s" % visible)
	print("   - Is animating: %s" % is_animating)
