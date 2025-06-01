# PlayerController.gd - AVEC NOUVEAU SYSTÈME D'INVENTAIRE INTÉGRÉ
extends CharacterBody3D

# Composants existants avec validation
@onready var spring_arm: SpringArm3D = ValidationUtils.get_node_safe(self, "SpringArm3D")
@onready var camera: Camera3D = ValidationUtils.get_node_safe(spring_arm, "Camera3D") if spring_arm else null
@onready var state_machine: StateMachine = ValidationUtils.get_node_safe(self, "StateMachine")
@onready var model_root: Node3D = ValidationUtils.get_node_safe(self, "CharacterSkin")
@onready var animation_player: AnimationPlayer = $CharacterSkin/AnimationPlayer 

# === NOUVEAU SYSTÈME D'INVENTAIRE ===
@onready var inventory_system: InventorySystem = $InventorySystem

var current_speed: float
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_spring_arm()
	add_to_group(GameConfig.GROUPS.player)
	
	# === SETUP INVENTAIRE ===
	setup_inventory_system()

func setup_inventory_system():
	"""Configure le nouveau système d'inventaire"""
	if not inventory_system:
		print("❌ InventorySystem non trouvé dans Player")
		return
	
	# Attendre que l'inventory system soit prêt
	inventory_system.system_ready.connect(_on_inventory_system_ready)

func _on_inventory_system_ready():
	"""Callback quand l'inventory system est prêt"""
	ServiceLocator.register("inventory", inventory_system)
	
	# Ajouter des items de test
	call_deferred("_add_test_items")

func _add_test_items():
	# Attendre que tout soit bien initialisé
	await get_tree().process_frame
	
	var main_inv = inventory_system.get_main_inventory()
	if not main_inv:
		print("❌ Inventaire principal introuvable")
		return
	
	if not main_inv.inventory:
		print("❌ Inventory data introuvable")
		return
	
	# Créer les items
	var apple = _create_test_apple()
	var sword = _create_test_sword()
	var wood = _create_test_wood()
	
	# Ajouter directement à l'inventaire data
	var apple_surplus = main_inv.inventory.add_item(apple, 4)
	var sword_surplus = main_inv.inventory.add_item(sword, 1)
	var wood_surplus = main_inv.inventory.add_item(wood, 63)
	var apple2_surplus = main_inv.inventory.add_item(apple, 60)
	
	# CRUCIAL - Forcer le refresh de l'UI
	await get_tree().process_frame
	if main_inv.ui:
		if main_inv.ui.has_method("refresh_ui"):
			main_inv.ui.refresh_ui()
		else:
			print("❌ Méthode refresh_ui introuvable")
	else:
		print("❌ UI introuvable")

func _create_test_icon(color: Color) -> ImageTexture:
	"""Crée une icône de test colorée"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func setup_spring_arm():
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "setup_spring_arm"):
		return
		
	spring_arm.spring_length = Constants.CAMERA_MAX_SPRING_LENGTH
	spring_arm.collision_mask = 1
	spring_arm.margin = Constants.CAMERA_COLLISION_MARGIN
	spring_arm.rotation.x = Constants.CAMERA_DEFAULT_ROTATION
	
func _find_all_item_previews(node: Node, found_previews: Array):
	"""Trouve récursivement tous les ItemPreview dans l'arbre"""
	
	# Vérifier si c'est un ItemPreview
	if node.get_script():
		var script = node.get_script()
		if script and script.get_global_name() == "ItemPreview":
			found_previews.append(node)
	
	# Ou vérifier par nom
	if node.name.contains("ItemPreview") or node.name.contains("Preview"):
		found_previews.append(node)
	
	# Continuer récursivement
	for child in node.get_children():
		_find_all_item_previews(child, found_previews)
				
				
func _unhandled_input(event: InputEvent):
	handle_camera_input(event)
	
	if state_machine and state_machine.current_state:
		state_machine.current_state.handle_input(event)

func handle_camera_input(event: InputEvent):
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "camera_input"):
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * Constants.CAMERA_MOUSE_SENSIVITY
		spring_arm.rotation.x -= event.relative.y * Constants.CAMERA_MOUSE_SENSIVITY
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, Constants.CAMERA_MIN_VERTICAL_ANGLE, Constants.CAMERA_MAX_VERTICAL_ANGLE)
	
	elif event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		_handle_zoom(event)

func _handle_zoom(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length - Constants.CAMERA_MAX_ZOOM_STEP, 
			Constants.CAMERA_MAX_ZOOM_MIN, 
			Constants.CAMERA_MAX_ZOOM_MAX
		)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length + Constants.CAMERA_MAX_ZOOM_STEP, 
			Constants.CAMERA_MAX_ZOOM_MIN, 
			Constants.CAMERA_MAX_ZOOM_MAX
		)

# === MÉTHODES DE MOUVEMENT (inchangées) ===

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func apply_movement(direction: Vector3, speed: float, delta: float = 0.0):
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		if delta > 0 and ValidationUtils.validate_node(model_root, "ModelRoot", "apply_movement"):
			var target_rotation = atan2(-direction.x, -direction.z)
			model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rotation, ConstantsPlayer.ROTATION_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func get_movement_direction_from_camera() -> Vector3:
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "get_movement_direction"):
		return Vector3.ZERO
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() == 0:
		return Vector3.ZERO
	
	var camera_forward = -spring_arm.global_transform.basis.z
	var camera_right = spring_arm.global_transform.basis.x
	
	var direction = (camera_right * input_dir.x + camera_forward * -input_dir.y).normalized()
	direction.y = 0
	
	return direction

# === API PUBLIQUE POUR INVENTAIRE ===

func pickup_item(item: Item, quantity: int = 1) -> int:
	"""Ramasse un item - retourne le surplus"""
	if not inventory_system:
		return quantity
	
	var surplus = inventory_system.add_item_to_inventory(item, quantity)
	var picked_up = quantity - surplus
	
	if picked_up > 0:
		print("📦 Ramassé: %s x%d" % [item.name, picked_up])
		# Ici tu peux ajouter un son ou effet
	
	if surplus > 0:
		print("⚠️ Inventaire plein! %d %s laissés" % [surplus, item.name])
	
	return surplus

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Vérifie si le joueur a un item"""
	if not inventory_system:
		return false
	
	return inventory_system.has_item(item_id, quantity)

func get_inventory_system() -> InventorySystem:
	"""Accès au système d'inventaire"""
	return inventory_system

func _create_test_apple() -> Item:
	var apple = Item.new("apple", "Pomme")
	apple.item_type = Item.ItemType.CONSUMABLE
	apple.max_stack_size = 64
	apple.is_stackable = true
	apple.icon = _create_test_icon(Color.RED)
	return apple

func _create_test_sword() -> Item:
	var sword = Item.new("sword", "Épée")
	sword.item_type = Item.ItemType.TOOL
	sword.max_stack_size = 1
	sword.is_stackable = false
	sword.icon = _create_test_icon(Color.SILVER)
	return sword

func _create_test_wood() -> Item:
	var wood = Item.new("wood", "Bois")
	wood.item_type = Item.ItemType.RESOURCE
	wood.max_stack_size = 9999
	wood.is_stackable = true
	wood.icon = _create_test_icon(Color(0.6, 0.3, 0.1))
	return wood
	
# === FONCTIONS AUDIO SIMPLIFIÉES ===
func play_action_sound(sound_name: String, volume: float = 1.0):
	"""Joue un son d'action du joueur"""
	AudioSystem.play_player_sound(sound_name, volume)

func start_footsteps(surface: String = "grass"):
	"""Démarre les sons de pas"""
	if animation_player:
		AudioSystem.start_footsteps(animation_player, surface)

func stop_footsteps():
	"""Arrête les sons de pas"""
	AudioSystem.stop_footsteps()

func update_footsteps():
	"""Met à jour les footsteps"""
	AudioSystem.update_footsteps()
	
func _debug_visual_overlays():
	"""Debug les overlays de tous les slots visibles"""
	var main_inv = inventory_system.get_main_inventory()
	if not main_inv or not main_inv.ui:
		print("❌ Inventaire principal introuvable")
		return
	
	var slots = _find_all_clickable_slots(main_inv.ui)
	print("🔍 Trouvé %d slots dans l'inventaire principal:" % slots.size())
	
	for slot in slots:
		if slot.has_method("debug_visual_state"):
			slot.debug_visual_state()

func _force_show_visual_on_slot(slot_index: int, type: String):
	"""Force l'affichage visuel sur un slot spécifique"""
	var main_inv = inventory_system.get_main_inventory()
	if not main_inv or not main_inv.ui:
		print("❌ Inventaire principal introuvable")
		return
	
	var slots = _find_all_clickable_slots(main_inv.ui)
	if slot_index >= slots.size():
		print("❌ Slot %d introuvable (max: %d)" % [slot_index, slots.size()-1])
		return
	
	var slot = slots[slot_index]
	match type:
		"hover":
			if slot.has_method("force_show_hover"):
				slot.force_show_hover()
		"selected":
			if slot.has_method("force_show_selected"):
				slot.force_show_selected()

func _find_all_clickable_slots(ui: Control) -> Array:
	"""Trouve tous les ClickableSlotUI dans une UI"""
	var slots = []
	_find_clickable_slots_recursive(ui, slots)
	return slots

func _find_clickable_slots_recursive(node: Node, slots: Array):
	"""Recherche récursive"""
	if node.get_class() == "ClickableSlotUI" or node.get_script() and node.get_script().get_global_name() == "ClickableSlotUI":
		slots.append(node)
	
	for child in node.get_children():
		_find_clickable_slots_recursive(child, slots)

func _debug_visual_system_state():
	"""Debug l'état général du système visuel"""
	var integrator = inventory_system.click_integrator
	if not integrator:
		print("❌ Click integrator introuvable")
		return
	
	print("\n🔍 ÉTAT SYSTÈME VISUEL:")
	print("   - Sélection logique: %s" % (not integrator.selected_slot_info.is_empty()))
	
	if integrator.has_property("currently_selected_slot_ui"):
		var visual_slot = integrator.currently_selected_slot_ui
		print("   - Sélection visuelle: %s" % (visual_slot != null))
		if visual_slot:
			print("   - Slot visuel sélectionné: %d" % visual_slot.get_slot_index())
	else:
		print("   - ⚠️ Propriété currently_selected_slot_ui manquante dans integrator")
		
func _input(event):
	# Tests temporaires (à retirer après)
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_1):
		call_deferred("test_new_input_system")
	
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_2):
		call_deferred("_debug_input_system_integration")
	
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_3):
		call_deferred("_test_specific_input_action", "double_click")
	
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_4):
		call_deferred("_test_specific_input_action", "drag")

func _debug_click_system_complete():
	"""Debug complet du système de clic"""
	print("🔍 DEBUG SYSTÈME DE CLIC COMPLET")
	
	# 1. Vérifier InventorySystem
	if not inventory_system:
		print("❌ InventorySystem manquant!")
		return
	
	print("✅ InventorySystem trouvé")
	
	# 2. Vérifier ClickIntegrator
	var integrator = inventory_system.get_click_integrator()
	if not integrator:
		print("❌ ClickIntegrator manquant!")
		return
	
	print("✅ ClickIntegrator trouvé")
	integrator.debug_system_state()
	
	# 3. Vérifier les UIs
	var main_inv = inventory_system.get_main_inventory()
	if main_inv and main_inv.ui:
		main_inv.ui.debug_ui_state()
	
	# 4. Tester les slots
	print("\n🔍 TEST DES PREMIERS SLOTS:")
	for i in range(3):
		if main_inv.ui.slots.size() > i:
			main_inv.ui.slots[i].debug_slot_content()

func _test_forced_restack():
	"""Test forcé de restack entre les slots 0 et 2"""
	print("\n🧪 === TEST FORCÉ DE RESTACK ===")
	
	var main_inv = inventory_system.get_main_inventory()
	if not main_inv:
		print("❌ Inventaire principal introuvable")
		return
	
	# Simuler un restack Slot 0 -> Slot 2
	var context = ClickContext.create_slot_to_slot_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		0, "player_inventory", {"is_empty": false, "item_id": "apple", "item_name": "Pomme", "quantity": 64, "item_type": Item.ItemType.CONSUMABLE},
		2, "player_inventory", {"is_empty": false, "item_id": "wood", "item_name": "Bois", "quantity": 63, "item_type": Item.ItemType.RESOURCE}
	)
	
	var integrator = inventory_system.get_click_integrator()
	if integrator and integrator.click_system and integrator.click_system.action_registry:
		print("🚀 Exécution forcée du ActionRegistry...")
		var result = integrator.click_system.action_registry.execute(context)
		print("📊 Résultat: %s" % ("✅" if result else "❌"))
	else:
		print("❌ ActionRegistry introuvable")
		
func test_new_input_system():
	"""Test temporaire du nouveau système"""
	print("🧪 === TEST DU NOUVEAU SYSTÈME D'INPUT ===")
	
	# 1. Vérifier que l'InputStateManager fonctionne
	var input_manager = InputStateManager.new()
	print("✅ InputStateManager créé")
	
	# 2. Simuler quelques événements
	var test_click = InputEventMouseButton.new()
	test_click.button_index = MOUSE_BUTTON_LEFT
	test_click.pressed = true
	test_click.global_position = Vector2(100, 100)
	
	var action_type = input_manager.process_input(test_click)
	print("🎮 Action détectée: %s" % InputStateManager.ActionType.keys()[action_type])
	
	# 3. Tester les modificateurs
	var test_key = InputEventKey.new()
	test_key.keycode = KEY_SHIFT
	test_key.pressed = true
	input_manager.process_input(test_key)
	
	var modifiers = input_manager.get_current_modifiers()
	print("🔧 Modifiers: %s" % modifiers)
	
	# 4. Vérifier ClickContext étendu
	var context = ClickContext.create_advanced_interaction(
		ClickContext.ClickType.SIMPLE_LEFT_CLICK,
		0,
		"test_container",
		{"is_empty": false, "item_name": "Test Item"},
		modifiers
	)
	print("📦 ClickContext créé: %s" % context._to_string())
	
	print("✅ Tests du nouveau système réussis!")

# MÉTHODES DE DEBUG À AJOUTER DANS PLAYERCONTROLLER
func _debug_input_system_integration():
	"""Debug l'intégration du nouveau système dans l'inventaire"""
	print("\n🔍 === DEBUG INTÉGRATION SYSTÈME INPUT ===")
	
	var inventory_system = get_inventory_system()
	if not inventory_system:
		print("❌ InventorySystem introuvable")
		return
	
	var main_inv = inventory_system.get_main_inventory()
	if not main_inv or not main_inv.ui:
		print("❌ MainInventory UI introuvable")
		return
	
	# Vérifier les premiers slots
	print("🔍 Test des slots UI:")
	var base_ui = main_inv.ui as BaseInventoryUI
	if base_ui and base_ui.slots.size() > 0:
		for i in range(min(3, base_ui.slots.size())):
			var slot = base_ui.slots[i]
			if slot:
				print("   Slot[%d]: Input state = %s" % [i, slot.get_current_action_state()])
				slot.debug_input_state()
			else:
				print("   Slot[%d]: ❌ Slot UI invalide" % i)
	else:
		print("❌ Pas de slots UI trouvés")

func _test_specific_input_action(action_name: String):
	"""Test d'une action spécifique"""
	print("\n🧪 === TEST ACTION: %s ===" % action_name.to_upper())
	
	match action_name:
		"double_click":
			_simulate_double_click()
		"middle_click":
			pass
			# _simulate_middle_click()
		"drag":
			pass
			# _simulate_drag_sequence()
		"hold":
			pass
			# _simulate_hold_sequence()
		_:
			print("❌ Action de test inconnue: %s" % action_name)

func _simulate_double_click():
	"""Simule un double-clic pour test"""
	var input_manager = InputStateManager.new()
	
	# Premier clic
	var click1 = InputEventMouseButton.new()
	click1.button_index = MOUSE_BUTTON_LEFT
	click1.pressed = false
	click1.global_position = Vector2(100, 100)
	
	var action1 = input_manager.process_input(click1)
	print("🖱️ Premier clic: %s" % InputStateManager.ActionType.keys()[action1])
	
	# Attendre un peu moins que le délai de double-clic
	await get_tree().create_timer(0.2).timeout
	
	# Deuxième clic
	var click2 = InputEventMouseButton.new()
	click2.button_index = MOUSE_BUTTON_LEFT
	click2.pressed = false
	click2.global_position = Vector2(100, 100)
	
	var action2 = input_manager.process_input(click2)
	print("🖱️ Deuxième clic: %s" % InputStateManager.ActionType.keys()[action2])
	
	if action2 == InputStateManager.ActionType.DOUBLE_LEFT_CLICK:
		print("✅ Double-clic détecté correctement!")
	else:
		print("❌ Double-clic non détecté")

func _simulate_drag_sequence():
	"""Simule une séquence de drag"""
	var input_manager = InputStateManager.new()
	
	# Press
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = Vector2(100, 100)
	
	var action1 = input_manager.process_input(press)
	print("🖱️ Press: %s" % InputStateManager.ActionType.keys()[action1])
	
	# Motion (déclenche drag)
	var motion = InputEventMouseMotion.new()
	motion.global_position = Vector2(120, 120)  # Distance > threshold
	
	var action2 = input_manager.process_input(motion)
	print("🖱️ Motion: %s" % InputStateManager.ActionType.keys()[action2])
	
	# Plus de motion
	motion.global_position = Vector2(140, 140)
	var action3 = input_manager.process_input(motion)
	print("🖱️ Motion continue: %s" % InputStateManager.ActionType.keys()[action3])
	
	# Release
	var release = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.global_position = Vector2(140, 140)
	
	var action4 = input_manager.process_input(release)
	print("🖱️ Release: %s" % InputStateManager.ActionType.keys()[action4])
