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
	var apple_surplus = main_inv.inventory.add_item(apple, 5)
	var sword_surplus = main_inv.inventory.add_item(sword, 1)
	var wood_surplus = main_inv.inventory.add_item(wood, 12)
	
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
	
func _input(event):
	# Ajoute ça dans ta fonction _input existante ou crée-la
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F4:
				print("🧪 Test sélection:")
				var integrator = inventory_system.click_integrator
				if integrator:
					print("   - Slot sélectionné: %s" % (not integrator.selected_slot_info.is_empty()))
					if not integrator.selected_slot_info.is_empty():
						print("   - Slot: %d, Container: %s" % [
							integrator.selected_slot_info.slot_index,
							integrator.selected_slot_info.container_id
						])
			
			KEY_F2:
				print("🧪 Test ajout item:")
				_force_add_test_item()
			
			KEY_F3:
				print("🧪 État click system:")
				if inventory_system.click_integrator:
					inventory_system.click_integrator.click_system.print_debug_info()

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

# === DEBUG ===

func debug_inventory():
	"""Affiche les infos de l'inventaire pour debug"""
	if inventory_system:
		inventory_system.debug_all_containers()
	else:
		print("❌ Pas d'inventory system")
		
func _force_add_test_item():
	"""Force l'ajout d'un item de test visible"""
	var test_item = Item.new()
	test_item.id = "debug_apple"
	test_item.name = "Pomme Debug"
	test_item.item_type = Item.ItemType.CONSUMABLE
	test_item.max_stack_size = 64
	test_item.is_stackable = true
	test_item.icon = _create_test_icon(Color.RED)
	
	var main_inv = inventory_system.get_main_inventory()
	if main_inv:
		var surplus = main_inv.add_item(test_item, 5)
		
		# Forcer le rafraîchissement de l'UI
		if main_inv.ui and main_inv.ui.has_method("refresh_ui"):
			main_inv.ui.refresh_ui()
			print("🔄 UI rafraîchie")
	else:
		print("❌ Inventaire principal introuvable")

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
	wood.max_stack_size = 99
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
