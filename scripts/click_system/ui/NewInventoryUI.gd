# scripts/click_system/ui/NewInventoryUI.gd
class_name NewInventoryUI
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var slots_grid: GridContainer = $VBoxContainer/SlotsGrid

var container: ClickableContainer
var inventory: Inventory
var controller: ClickableInventoryController
var slots: Array[ClickableSlotUI] = []

# Animation
var tween: Tween
var animation_duration: float = 0.4

func _ready():
	# Cacher par défaut
	hide_immediately()

func hide_immediately():
	"""Cache immédiatement sans animation"""
	visible = false
	position.y = get_viewport().get_visible_rect().size.y + size.y

# === SETUP AVEC CLICKABLE CONTAINER ===

func setup_with_clickable_container(clickable_container: ClickableContainer):
	"""Configure l'UI avec le nouveau système"""
	container = clickable_container
	inventory = container.get_inventory()
	controller = container.get_controller()
	
	# Configurer le titre
	if title_label:
		title_label.text = inventory.name.to_upper()
	
	# Créer les slots
	_create_slots()
	
	# Connecter les signaux de l'inventaire
	if inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Premier refresh
	refresh_ui()
	
	print("✅ NewInventoryUI configurée avec %d slots" % inventory.size)

func _create_slots():
	"""Crée tous les slots clickables"""
	if not slots_grid:
		print("❌ SlotsGrid introuvable")
		return
	
	# Nettoyer les slots existants
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	# Créer les nouveaux slots
	for i in inventory.size:
		var slot = ClickableSlotUI.new()
		slot.set_slot_index(i)
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = Vector2(64, 64)
		
		# Créer les composants du slot
		_setup_slot_components(slot)
		
		# Ajouter au grid
		slots_grid.add_child(slot)
		slots.append(slot)
		
		print("✅ Slot %d créé" % i)

func _setup_slot_components(slot: ClickableSlotUI):
	"""Configure les composants visuels d'un slot"""
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.2, 0.2, 0.3, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	slot.add_child(bg)
	
	# ItemIcon
	var icon = TextureRect.new()
	icon.name = "ItemIcon"
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)
	
	# QuantityLabel
	var qty_label = Label.new()
	qty_label.name = "QuantityLabel"
	qty_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	qty_label.offset_left = -24
	qty_label.offset_top = -18
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.add_theme_font_size_override("font_size", 12)
	qty_label.visible = false
	slot.add_child(qty_label)
	
	# Button (invisible pour capturer les clics)
	var button = Button.new()
	button.name = "Button"
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.add_child(button)

# === REFRESH ET MISE À JOUR ===

func refresh_ui():
	"""Met à jour l'affichage de tous les slots"""
	if not controller or not inventory:
		return
	
	for i in slots.size():
		if i < inventory.size:
			var slot_data = controller.get_slot_info(i)
			if slots[i] and is_instance_valid(slots[i]):
				slots[i].update_slot(slot_data)

func _on_inventory_changed():
	"""Callback quand l'inventaire change"""
	call_deferred("refresh_ui")

# === ANIMATIONS ===

func show_animated():
	"""Animation d'apparition depuis le bas"""
	if tween and tween.is_valid():
		tween.kill()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Position finale centrée
	var final_x = (viewport_size.x - size.x) / 2
	var final_y = viewport_size.y - size.y - 20
	
	# Position de départ (cachée en bas)
	var start_x = final_x
	var start_y = viewport_size.y + 50
	
	# Positionner et afficher
	position = Vector2(start_x, start_y)
	visible = true
	modulate = Color(1, 1, 1, 0.8)
	
	# Animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(self, "position", Vector2(final_x, final_y), animation_duration)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, animation_duration * 0.6)

func hide_animated():
	"""Animation de disparition vers le bas"""
	if tween and tween.is_valid():
		tween.kill()
	
	var viewport_size = get_viewport().get_visible_rect().size
	var final_y = viewport_size.y + 50
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "position", Vector2(position.x, final_y), animation_duration * 0.7)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), animation_duration * 0.5)
	
	tween.tween_callback(func(): 
		visible = false
		print("🎬 Inventaire masqué")
	)

# === DEBUG ===

func debug_info():
	print("\n📦 NewInventoryUI Debug:")
	print("   - Slots créés: %d" % slots.size())
	print("   - Inventory size: %d" % (inventory.size if inventory else 0))
	print("   - Controller: %s" % str(controller))
