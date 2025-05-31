# scripts/click_system/ui/NewInventoryUI.gd - VERSION CORRIGÉE
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
	hide_immediately()

func hide_immediately():
	"""Cache immédiatement sans animation"""
	visible = false
	position.y = get_viewport().get_visible_rect().size.y + size.y

# === SETUP AVEC CLICKABLE CONTAINER ===
func _create_slots_programmatically():
	"""Crée les slots depuis la scène ClickableSlotUI.tscn"""
	print("🔧 Création de %d slots depuis la scène..." % inventory.size)
	
	if not slots_grid:
		print("❌ SlotsGrid introuvable")
		return
	
	# FORCER la visibilité du grid AVANT tout
	slots_grid.visible = true
	slots_grid.modulate = Color.WHITE
	
	# Nettoyer les slots existants
	for slot in slots:
		if is_instance_valid(slot):
			slot.queue_free()
	slots.clear()
	
	for child in slots_grid.get_children():
		child.queue_free()
	
	# ATTENDRE le nettoyage
	await get_tree().process_frame
	
	# CONFIGURATION FORCÉE DU GRID
	slots_grid.columns = 9
	
	# FORCER la taille AVANT de créer les slots
	var rows = ceil(float(inventory.size) / 9.0)
	var grid_width = 9 * 68  # 64px + 4px spacing
	var grid_height = rows * 68
	
	# Plusieurs méthodes pour forcer la taille
	slots_grid.custom_minimum_size = Vector2(grid_width, grid_height)
	slots_grid.size = Vector2(grid_width, grid_height)
	
	# IMPORTANT : Changer les size flags pour empêcher le redimensionnement auto
	slots_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slots_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Forcer les séparations
	slots_grid.add_theme_constant_override("h_separation", 4)
	slots_grid.add_theme_constant_override("v_separation", 4)
	
	print("🔧 Grid configuré: taille forcée à %s" % slots_grid.size)
	
	# CHARGER LA SCÈNE
	var slot_scene = load("res://scenes/test/click_system/ui/ClickableSlotUI.tscn")
	if not slot_scene:
		print("❌ Impossible de charger ClickableSlotUI.tscn")
		# TEST : Créer un slot simple pour vérifier
		_create_test_slot()
		return
	
	# Créer les slots depuis la scène
	for i in inventory.size:
		var slot = slot_scene.instantiate()
		slot.set_slot_index(i)
		slot.name = "Slot_%d" % i
		
		# FORCER la taille du slot aussi
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = Vector2(64, 64)
		
		# FORCER la visibilité
		slot.visible = true
		
		# Connecter les signaux
		if slot.has_signal("slot_clicked"):
			slot.slot_clicked.connect(_on_slot_clicked)
		
		slots_grid.add_child(slot)
		slots.append(slot)
		
		print("✅ Slot %d créé (taille: %s, visible: %s)" % [i, slot.size, slot.visible])
	
	# FORCER un recalcul après création
	await get_tree().process_frame
	slots_grid.queue_redraw()
	
	print("✅ Total slots créés: %d" % slots.size())
	
	# DEBUG : Vérifier l'état final
	call_deferred("debug_grid_after_creation")

func _create_test_slot():
	"""Crée un slot de test simple pour vérifier que le grid fonctionne"""
	print("🧪 Création d'un slot de test...")
	
	var test_slot = ColorRect.new()
	test_slot.name = "TestSlot"
	test_slot.size = Vector2(64, 64)
	test_slot.custom_minimum_size = Vector2(64, 64)
	test_slot.color = Color.RED  # Rouge vif pour le voir
	
	slots_grid.add_child(test_slot)
	print("🧪 Slot de test rouge ajouté - tu devrais le voir !")

func debug_grid_after_creation():
	"""Debug complet après création"""
	print("\n🔍 === DEBUG GRID APRÈS CRÉATION ===")
	
	if not slots_grid:
		print("❌ slots_grid est null!")
		return
	
	print("📏 Grid - Size: %s" % slots_grid.size)
	print("📏 Grid - Min size: %s" % slots_grid.custom_minimum_size)
	print("📏 Grid - Position: %s" % slots_grid.position)
	print("📏 Grid - Visible: %s" % slots_grid.visible)
	print("📏 Grid - Modulate: %s" % slots_grid.modulate)
	print("📏 Grid - Columns: %d" % slots_grid.columns)
	print("📏 Grid - Children count: %d" % slots_grid.get_child_count())
	
	# Vérifier les enfants
	print("📋 Enfants du grid:")
	for i in range(min(5, slots_grid.get_child_count())):
		var child = slots_grid.get_child(i)
		print("   [%d] %s - Size: %s, Visible: %s" % [i, child.name, child.size, child.visible])
	
	# Vérifier le parent aussi
	print("📋 Parent VBoxContainer:")
	var vbox = slots_grid.get_parent()
	if vbox:
		print("   - Size: %s" % vbox.size)
		print("   - Visible: %s" % vbox.visible)
	
	# Vérifier la root
	print("📋 Root Control:")
	print("   - Size: %s" % size)
	print("   - Visible: %s" % visible)

# AJOUTE AUSSI cette méthode dans setup_with_clickable_container :
func setup_with_clickable_container(clickable_container: ClickableContainer):
	"""Configure l'UI avec le nouveau système"""
	container = clickable_container
	inventory = container.get_inventory()
	controller = container.get_controller()
	
	print("🔧 Setup UI avec inventory size: %d" % inventory.size)
	
	# Configurer le titre
	if title_label:
		title_label.text = inventory.name.to_upper()
	
	# CORRECTION : Attendre que l'UI soit complètement prête
	await get_tree().process_frame
	await get_tree().process_frame
	
	# DEBUG : Vérifier l'état initial
	print("🔍 État initial - UI size: %s, visible: %s" % [size, visible])
	if slots_grid:
		print("🔍 État initial - Grid size: %s, visible: %s" % [slots_grid.size, slots_grid.visible])
	
	# Créer les slots
	await _create_slots_programmatically()
	
	# Connecter les signaux de l'inventaire
	if inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Premier refresh
	await get_tree().process_frame
	refresh_ui()
	
func _create_slots_manually():
	"""Fallback : Crée les slots en code pur"""
	print("🔧 Fallback - Création manuelle des slots...")
	
	for i in inventory.size:
		var slot = ClickableSlotUI.new()
		slot.set_slot_index(i)
		slot.name = "Slot_%d" % i
		slot.custom_minimum_size = Vector2(64, 64)
		slot.size = Vector2(64, 64)
		
		# Créer les composants manuellement
		_setup_slot_components_manually(slot)
		
		# Connecter les signaux
		slot.slot_clicked.connect(_on_slot_clicked)
		
		slots_grid.add_child(slot)
		slots.append(slot)

func _create_clickable_slot_manually(index: int) -> ClickableSlotUI:
	"""Crée un ClickableSlotUI manuellement"""
	var slot = ClickableSlotUI.new()
	slot.set_slot_index(index)
	slot.name = "Slot_%d" % index
	slot.custom_minimum_size = Vector2(64, 64)
	slot.size = Vector2(64, 64)
	
	# IMPORTANT : Créer les composants manuellement
	
	# Connecter les signaux au click system
	slot.slot_clicked.connect(_on_slot_clicked)
	
	return slot

func _setup_slot_button(slot: ClickableSlotUI):
	"""Configure le bouton du slot après création"""
	if slot.has_method("setup_button"):
		slot.setup_button()

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Gestionnaire de clic unifié"""
	print("🎯 Clic reçu: slot %d, bouton %d" % [slot_index, mouse_event.button_index])
	
	if not controller:
		print("❌ Pas de controller")
		return
	
	var slot_data = controller.get_slot_info(slot_index)
	
	# Passer au click system via le container
	if container and container.get_script().get_path().has("ClickableContainer"):
		# Trouver le click integrator dans l'arbre
		var click_integrator = _find_click_integrator()
		if click_integrator:
			click_integrator._on_slot_clicked(slot_index, mouse_event, container.get_container_id())
		else:
			print("❌ Click integrator introuvable")

func _find_click_integrator():
	"""Trouve le ClickSystemIntegrator dans l'arbre"""
	var current = self
	while current:
		# Chercher dans les enfants
		for child in current.get_children():
			if child.get_script() and "ClickSystemIntegrator" in str(child.get_script().resource_path):
				return child
		
		current = current.get_parent()
		
		# Sécurité
		if current is SceneTree or not current:
			break
	
	# Chercher dans toute la scène si pas trouvé
	return _find_in_scene_tree("ClickSystemIntegrator")

func _find_in_scene_tree(_class_name: String):
	"""Cherche récursivement dans toute la scène"""
	var scene_root = get_tree().current_scene
	return _search_recursive(scene_root, _class_name)

func _search_recursive(node: Node, search_class: String):
	"""Recherche récursive"""
	if node.get_script() and search_class in str(node.get_script().resource_path):
		return node
	
	for child in node.get_children():
		var result = _search_recursive(child, search_class)
		if result:
			return result
	
	return null

func refresh_ui():
	"""Met à jour l'affichage de tous les slots"""
	if not controller or not inventory:
		return
	
	for i in slots.size():
		if i < inventory.size and slots[i] and is_instance_valid(slots[i]):
			var slot_data = controller.get_slot_info(i)
			slots[i].update_slot(slot_data)

func _on_inventory_changed():
	"""Callback quand l'inventaire change"""
	call_deferred("refresh_ui")

# === ANIMATIONS (inchangées) ===

func show_animated():
	"""Animation d'apparition depuis le bas"""
	if tween and tween.is_valid():
		tween.kill()
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	var final_x = (viewport_size.x - size.x) / 2
	var final_y = viewport_size.y - size.y - 20
	
	var start_x = final_x
	var start_y = viewport_size.y + 50
	
	position = Vector2(start_x, start_y)
	visible = true
	modulate = Color(1, 1, 1, 0.8)
	
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
	print("   - Grid children: %d" % (slots_grid.get_child_count() if slots_grid else 0))
	
func _setup_slot_components_manually(slot: ClickableSlotUI):
	"""Setup manuel des composants (fallback uniquement)"""
	var bg = ColorRect.new()
	bg.name = "ColorRect"
	bg.color = Color(0.09, 0.125, 0.22, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	slot.add_child(bg)
	
	var icon = TextureRect.new()
	icon.name = "ItemIcon"
	icon.anchors_preset = Control.PRESET_FULL_RECT
	icon.offset_left = 8
	icon.offset_top = 8
	icon.offset_right = -8
	icon.offset_bottom = -8
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)
	
	var qty_label = Label.new()
	qty_label.name = "QuantityLabel"
	qty_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	qty_label.offset_left = -20
	qty_label.offset_top = -20
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.visible = false
	slot.add_child(qty_label)
	
	var button = Button.new()
	button.name = "Button"
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.add_child(button)
	
	call_deferred("_setup_slot_button", slot)
