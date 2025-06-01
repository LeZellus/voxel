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
	# Tes autres touches de debug existantes...
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Tes touches existantes...
			
			# NOUVELLES TOUCHES DEBUG PREVIEW
			KEY_F1:
				print("🧪 Test preview:")
				var integrator = inventory_system.click_integrator
				if integrator:
					integrator.print_debug_info()
				else:
					print("   - ❌ Click integrator introuvable")
			
			KEY_F2:
				print("🔧 Force création preview:")
				var integrator = inventory_system.click_integrator
				if integrator and integrator.has_method("force_create_preview"):
					integrator.force_create_preview()
				else:
					print("   - ❌ Impossible de forcer la création")
			
			KEY_F3:
				print("🧪 Test affichage preview manuel:")
				var integrator = inventory_system.click_integrator
				if integrator and integrator.item_preview:
					var test_data = {
						"is_empty": false,
						"item_name": "Test Item",
						"quantity": 5,
						"icon": _create_test_icon(Color.BLUE)
					}
					integrator._show_item_preview(test_data)
					
					# NOUVEAU: Forcer position au centre de l'écran
					var viewport_size = get_viewport().get_visible_rect().size
					var center_pos = viewport_size / 2
					integrator.item_preview.position = center_pos
					print("🎯 Preview forcée au centre: %s" % center_pos)
				else:
					print("   - ❌ Preview ou integrator manquant")
			
			KEY_F4:
				print("🧪 Cache preview:")
				var integrator = inventory_system.click_integrator
				if integrator:
					integrator._hide_item_preview()
				else:
					print("   - ❌ Integrator manquant")
			
			# NOUVELLE TOUCHE POUR DEBUG ITEMPREVIEW INTERNE
			KEY_F5:
				print("🔍 Debug état ItemPreview:")
				var integrator = inventory_system.click_integrator
				if integrator and integrator.item_preview:
					if integrator.item_preview.has_method("debug_state"):
						integrator.item_preview.debug_state()
					else:
						print("   - ❌ Méthode debug_state manquante")
				else:
					print("   - ❌ ItemPreview introuvable")
			
			# NOUVELLE TOUCHE : Afficher preview en position fixe
			KEY_F6:
				print("🎯 Test preview position fixe:")
				var integrator = inventory_system.click_integrator
				if integrator and integrator.item_preview:
					var preview = integrator.item_preview
					
					# Forcer visible au centre
					preview.visible = true
					preview.is_active = true
					preview.position = Vector2(500, 300)  # Position fixe
					preview.z_index = 2000
					
					print("✅ Preview forcée visible à (500, 300)")
					print("   - Position: %s" % preview.position)
					print("   - Visible: %s" % preview.visible)
					print("   - Z-index: %s" % preview.z_index)
				else:
					print("   - ❌ Preview introuvable")
			
			# NOUVELLE TOUCHE : DEBUG HIÉRARCHIE COMPLÈTE
			KEY_F7:
				print("🔍 DEBUG HIÉRARCHIE PREVIEW:")
				var integrator = inventory_system.click_integrator
				if integrator and integrator.item_preview:
					var preview = integrator.item_preview
					print("📋 Hiérarchie complète:")
					print("   - Preview parent: %s" % (preview.get_parent().name if preview.get_parent() else "null"))
					print("   - Preview enfants: %d" % preview.get_child_count())
					
					# Remonter la hiérarchie
					var current = preview
					var depth = 0
					while current and depth < 10:
						var indent = "  ".repeat(depth)
						print("%s- %s (Type: %s, Visible: %s)" % [
							indent, 
							current.name, 
							current.get_class(),
							current.visible if current.has_method("visible") else "N/A"
						])
						current = current.get_parent()
						depth += 1
				else:
					print("   - ❌ Preview introuvable")
			
			# NOUVELLE TOUCHE : RECRÉER PREVIEW DIRECTEMENT DANS SCÈNE
			KEY_F8:
				print("🔧 RECRÉATION PREVIEW DIRECTE (VERSION SÉCURISÉE):")
				
				var integrator = inventory_system.click_integrator
				if not integrator:
					print("❌ Integrator introuvable")
					return
				
				print("📋 État avant suppression:")
				print("   - ItemPreview existe: %s" % (integrator.item_preview != null))
				
				if integrator.item_preview:
					print("   - ItemPreview valide: %s" % is_instance_valid(integrator.item_preview))
					print("   - ItemPreview nom: %s" % integrator.item_preview.name)
					print("   - ItemPreview parent: %s" % (integrator.item_preview.get_parent().name if integrator.item_preview.get_parent() else "null"))
					print("   - ItemPreview is_active: %s" % integrator.item_preview.is_active)
					
					# ÉTAPE 1: Cacher d'abord
					print("🔧 Étape 1: Masquage sécurisé...")
					integrator.item_preview.hide_item()
					integrator.item_preview.visible = false
					integrator.item_preview.is_active = false
					
					# ÉTAPE 2: Déconnecter de l'integrator
					print("🔧 Étape 2: Déconnexion de l'integrator...")
					integrator.item_preview = null
					
					# ÉTAPE 3: Attendre un frame
					print("🔧 Étape 3: Attente d'un frame...")
					await get_tree().process_frame
					
					# ÉTAPE 4: Chercher manuellement les ItemPreview dans la scène
					print("🔧 Étape 4: Nettoyage manuel...")
					var main_scene = get_tree().current_scene
					var previews_found = []
					
					_find_all_item_previews(main_scene, previews_found)
					
					print("📋 Trouvé %d ItemPreview(s) dans la scène:" % previews_found.size())
					for i in range(previews_found.size()):
						var preview = previews_found[i]
						print("   - Preview %d: %s (Parent: %s)" % [
							i, 
							preview.name, 
							preview.get_parent().name if preview.get_parent() else "null"
						])
						
						# Suppression sécurisée
						if is_instance_valid(preview):
							preview.queue_free()
							print("   ✅ Preview %d supprimée" % i)
						else:
							print("   ⚠️ Preview %d déjà invalide" % i)
					
					# ÉTAPE 5: Attendre encore
					await get_tree().process_frame
				
				print("🔧 Étape finale: Création d'une nouvelle preview...")
				
				# Créer une nouvelle preview simple
				var ItemPreviewScript = load("res://scripts/ui/components/ItemPreview.gd")
				if not ItemPreviewScript:
					print("❌ Script ItemPreview.gd introuvable")
					return
				
				var new_preview = ItemPreviewScript.new()
				new_preview.name = "TestDirectItemPreview"
				
				# Ajouter DIRECTEMENT à la scène principale
				var main_scene = get_tree().current_scene
				main_scene.add_child(new_preview)
				
				# Attendre que ça soit prêt
				await get_tree().process_frame
				await get_tree().process_frame
				
				# Test immédiat
				print("🧪 Test de la nouvelle preview...")
				new_preview.visible = true
				new_preview.position = Vector2(200, 200)
				new_preview.z_index = 9999
				new_preview.modulate = Color.GREEN  # Vert pour la distinguer
				
				print("✅ Nouvelle preview créée en VERT à (200, 200)")
				print("   - Parent: %s" % new_preview.get_parent().name)
				print("   - Visible: %s" % new_preview.visible)
				print("   - Nom: %s" % new_preview.name)
				
				
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
