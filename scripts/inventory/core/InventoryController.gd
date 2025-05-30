# scripts/inventory/core/InventoryController.gd - VERSION CORRIGÉE
class_name InventoryController
extends RefCounted

signal action_performed(action_type: String, result: bool)

var inventory: Inventory
var command_system: CommandSystem
var interaction_manager: InteractionManager

func _init(inventory_data: Inventory):
	inventory = inventory_data
	command_system = CommandSystem.new()
	interaction_manager = InteractionManager.new(self)
	_connect_signals()

func _connect_signals():
	command_system.command_executed.connect(_on_command_executed)
	command_system.command_undone.connect(_on_command_undone)
	interaction_manager.interaction_completed.connect(_on_interaction_completed)

# === ACTIONS PRINCIPALES ===
func move_item(from_slot: int, to_slot: int) -> bool:
	var command = MoveItemCommand.new(inventory, from_slot, to_slot)
	var result = command_system.execute(command)
	action_performed.emit("move_item", result)
	return result

func add_item_to_inventory(item: Item, quantity: int = 1) -> int:
	var surplus = inventory.add_item(item, quantity)
	var added = quantity - surplus
	if added > 0:
		action_performed.emit("add_item", true)
	return surplus

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> int:
	var removed = inventory.remove_item(item_id, quantity)
	if removed > 0:
		action_performed.emit("remove_item", true)
	return removed

# === COMMANDES AVANCÉES ===
func quick_move_item(_slot_index: int) -> bool:
	print("Quick move pas encore implémenté")
	return false

func split_stack(_slot_index: int, _split_amount: int) -> bool:
	print("Split stack pas encore implémenté")
	return false

func stack_all_items(_item_id: String) -> bool:
	print("Stack all pas encore implémenté")
	return false

# === UNDO/REDO ===
func undo_last_action() -> bool:
	var result = command_system.undo()
	if result:
		action_performed.emit("undo", true)
	return result

func redo_last_action() -> bool:
	var result = command_system.redo()
	if result:
		action_performed.emit("redo", true)
	return result

func can_undo() -> bool:
	return command_system.can_undo()

func can_redo() -> bool:
	return command_system.can_redo()

# === QUERIES POUR L'UI - VERSION CORRIGÉE ===
func get_slot_info(slot_index: int) -> Dictionary:
	var slot = inventory.get_slot(slot_index)
	if not slot:
		print("❌ Slot %d introuvable" % slot_index)
		return {"is_empty": true, "index": slot_index}
	
	var info = {
		"index": slot.index,
		"is_empty": slot.is_empty(),
		"is_locked": slot.is_locked
	}
	
	if not slot.is_empty():
		var item = slot.get_item()
		if not item:
			print("❌ Item null dans le slot %d" % slot_index)
			return {"is_empty": true, "index": slot_index}
		
		# DEBUG: Vérifier l'icône de l'item
		print("🔍 Item %s - Icône: %s (type: %s)" % [
			item.name, 
			str(item.icon), 
			str(type_string(typeof(item.icon)))
		])
		
		info.merge({
			"item_id": item.id,
			"item_name": item.name,
			"quantity": slot.get_quantity(),
			"max_stack": item.max_stack_size,
			"icon": _validate_icon(item.icon, item.name)
		})
	
	return info

func _validate_icon(icon: Texture2D, item_name: String) -> Texture2D:
	"""Valide et retourne une icône ou crée un fallback"""
	if icon and icon is Texture2D:
		return icon
	
	print("⚠️ Icône manquante pour %s, création d'un fallback" % item_name)
	return _create_fallback_icon(item_name)

func _create_fallback_icon(item_name: String) -> ImageTexture:
	"""Crée une icône de fallback colorée selon le nom de l'item"""
	var color = Color.WHITE
	
	# Couleurs selon le type d'item (basé sur le nom)
	if "apple" in item_name.to_lower():
		color = Color.RED
	elif "wood" in item_name.to_lower():
		color = Color(0.6, 0.3, 0.1)
	elif "sword" in item_name.to_lower() or "épée" in item_name.to_lower():
		color = Color.SILVER
	elif "stone" in item_name.to_lower():
		color = Color.GRAY
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func get_inventory_summary() -> Dictionary:
	return {
		"name": inventory.name,
		"size": inventory.get_size(),
		"used_slots": inventory.get_used_slots_count(),
		"free_slots": inventory.get_free_slots_count(),
		"is_full": inventory.is_full(),
		"is_empty": inventory.is_empty()
	}

# === VALIDATION ===
func can_move_item(from_slot: int, to_slot: int) -> bool:
	var command = MoveItemCommand.new(inventory, from_slot, to_slot)
	return command.can_execute()

func can_add_item(item: Item, _quantity: int = 1) -> bool:
	if not item:
		return false
	return inventory.get_free_slots_count() > 0 or inventory.find_stackable_slot(item) >= 0

# === GESTION DES SIGNAUX ===
func _on_command_executed(command: Command):
	print("🎮 Controller: ", command.get_description(), " exécutée")

func _on_command_undone(command: Command):
	print("🎮 Controller: ", command.get_description(), " annulée")

func _on_interaction_completed(interaction_type: String, success: bool):
	print("🎮 Interaction ", interaction_type, " terminée:", success)
