# PlayerController.gd - AVEC NOUVEAU SYSTÈME D'INVENTAIRE INTÉGRÉ
extends CharacterBody3D

# Configuration depuis GameConfig
@export var walk_speed: float = GameConfig.PLAYER.walk_speed
@export var run_speed: float = GameConfig.PLAYER.run_speed
@export var jump_velocity: float = GameConfig.PLAYER.jump_velocity
@export var rotation_speed: float = GameConfig.PLAYER.rotation_speed

@export var mouse_sensitivity: float = GameConfig.CAMERA.mouse_sensitivity
@export var min_vertical_angle: float = GameConfig.CAMERA.min_vertical_angle
@export var max_vertical_angle: float = GameConfig.CAMERA.max_vertical_angle

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
	GameConfig.validate_config()
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
	print("🎮 Inventory system en cours d'initialisation...")

func _on_inventory_system_ready():
	"""Callback quand l'inventory system est prêt"""
	print("✅ Inventory system intégré au joueur")
	
	# Ajouter des items de test
	call_deferred("_add_test_items")
	
	# Setup input pour l'inventaire
	_setup_inventory_input()

func _add_test_items():
	"""Ajoute des items de test"""
	print("🧪 Ajout d'items de test...")
	
	# Créer quelques items de test
	var apple = Item.new()
	apple.id = "apple"
	apple.name = "Pomme"
	apple.item_type = Item.ItemType.CONSUMABLE
	apple.max_stack_size = 64
	apple.is_stackable = true
	apple.icon = _create_test_icon(Color.RED)
	
	var sword = Item.new()
	sword.id = "sword"
	sword.name = "Épée"
	sword.item_type = Item.ItemType.TOOL
	sword.max_stack_size = 1
	sword.is_stackable = false
	sword.icon = _create_test_icon(Color.SILVER)
	
	var wood = Item.new()
	wood.id = "wood"
	wood.name = "Bois"
	wood.item_type = Item.ItemType.RESOURCE
	wood.max_stack_size = 99
	wood.is_stackable = true
	wood.icon = _create_test_icon(Color(0.6, 0.3, 0.1))
	
	# Ajouter à l'inventaire
	inventory_system.add_item_to_inventory(apple, 15)
	inventory_system.add_item_to_inventory(sword, 1)
	inventory_system.add_item_to_inventory(wood, 32)
	
	# Ajouter quelques items à la hotbar
	inventory_system.add_item_to_hotbar(apple, 5)
	inventory_system.add_item_to_hotbar(sword, 1)
	
	print("✅ Items de test ajoutés")

func _create_test_icon(color: Color) -> ImageTexture:
	"""Crée une icône de test colorée"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _setup_inventory_input():
	"""Configure les raccourcis spécifiques au joueur"""
	
	# Déjà géré par InventorySystem pour le toggle inventaire (E)
	# Ici on peut ajouter d'autres raccourcis si nécessaire
	
	print("⌨️ Raccourcis inventaire configurés")

func setup_spring_arm():
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "setup_spring_arm"):
		return
		
	var config = GameConfig.CAMERA
	spring_arm.spring_length = config.spring_length
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.5
	spring_arm.rotation.x = -0.3
	
func _input(event):
	# Ajoute ça dans ta fonction _input existante ou crée-la
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("🧪 Debug inventaire:")
				inventory_system.debug_all_containers()
			
			KEY_F2:
				print("🧪 Test ajout item:")
				_force_add_test_item()
			
			KEY_F3:
				print("🧪 État click system:")
				if inventory_system.click_integrator:
					inventory_system.click_integrator.click_system.print_debug_info()
			
			KEY_F4:
				print("🧪 ActionManager debug:")
				if inventory_system.click_integrator and inventory_system.click_integrator.click_system.action_manager:
					inventory_system.click_integrator.click_system.action_manager.debug_handlers()

func _unhandled_input(event: InputEvent):
	handle_camera_input(event)
	
	if state_machine and state_machine.current_state:
		state_machine.current_state.handle_input(event)

func handle_camera_input(event: InputEvent):
	if not ValidationUtils.validate_node(spring_arm, "SpringArm3D", "camera_input"):
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_vertical_angle, max_vertical_angle)
	
	elif event is InputEventMouseButton and Input.is_key_pressed(KEY_CTRL):
		_handle_zoom(event)

func _handle_zoom(event: InputEventMouseButton):
	var config = GameConfig.CAMERA
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length - config.zoom_step, 
			config.zoom_min, 
			config.zoom_max
		)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		spring_arm.spring_length = clamp(
			spring_arm.spring_length + config.zoom_step, 
			config.zoom_min, 
			config.zoom_max
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
			model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rotation, rotation_speed * delta)
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
		print("📦 Item ajouté: %s x%d (surplus: %d)" % [test_item.name, 5-surplus, surplus])
		
		# Forcer le rafraîchissement de l'UI
		if main_inv.ui and main_inv.ui.has_method("refresh_ui"):
			main_inv.ui.refresh_ui()
			print("🔄 UI rafraîchie")
	else:
		print("❌ Inventaire principal introuvable")
