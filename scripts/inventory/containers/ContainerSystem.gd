# scripts/inventory/containers/ContainerSystem.gd
class_name ContainerSystem
extends Node

# === GESTIONNAIRE CENTRAL DES CONTENEURS ===

signal container_opened(container_id: String)
signal container_closed(container_id: String)
signal item_transferred(from_container: String, to_container: String, item_id: String, quantity: int)

var containers: Dictionary = {}
var active_containers: Array[String] = []
var drag_manager: DragDropManager

func _ready():
	setup_drag_manager()

func setup_drag_manager():
	drag_manager = DragDropManager.new()
	add_child(drag_manager)
	
	drag_manager.drag_completed.connect(_on_cross_container_drag)

# === GESTION DES CONTENEURS ===
func register_container(container_id: String, container: BaseContainer):
	containers[container_id] = container
	container.container_system = self
	print("📦 Container registered: ", container_id)

func unregister_container(container_id: String):
	if container_id in containers:
		containers.erase(container_id)
		active_containers.erase(container_id)

func get_container(container_id: String) -> BaseContainer:
	return containers.get(container_id)

func open_container(container_id: String):
	if container_id not in containers:
		return
	
	if container_id not in active_containers:
		active_containers.append(container_id)
	
	containers[container_id].show_ui()
	container_opened.emit(container_id)

func close_container(container_id: String):
	if container_id in active_containers:
		active_containers.erase(container_id)
	
	if container_id in containers:
		containers[container_id].hide_ui()
	
	container_closed.emit(container_id)

# === TRANSFERTS ENTRE CONTENEURS ===
func _on_cross_container_drag(source_info: Dictionary, target_info: Dictionary):
	var source_container = source_info.container_id
	var target_container = target_info.container_id
	var source_slot = source_info.slot_index
	var target_slot = target_info.slot_index
	
	if source_container == target_container:
		# Même conteneur - utiliser le move normal
		containers[source_container].controller.move_item(source_slot, target_slot)
	else:
		# Cross-container transfer
		transfer_item(source_container, source_slot, target_container, target_slot)

func transfer_item(from_container_id: String, from_slot: int, to_container_id: String, to_slot: int) -> bool:
	var from_container = get_container(from_container_id)
	var to_container = get_container(to_container_id)
	
	if not from_container or not to_container:
		return false
	
	var from_inventory = from_container.inventory
	var to_inventory = to_container.inventory
	
	var from_slot_obj = from_inventory.get_slot(from_slot)
	if from_slot_obj.is_empty():
		return false
	
	var item = from_slot_obj.get_item()
	var quantity = from_slot_obj.get_quantity()
	
	# Essayer d'ajouter à l'inventaire de destination
	var to_slot_obj = to_inventory.get_slot(to_slot)
	
	if to_slot_obj.is_empty() or to_slot_obj.can_accept_item(item, quantity):
		# Transfer possible
		var removed_stack = from_slot_obj.remove_item(quantity)
		var surplus = to_slot_obj.add_item(removed_stack.item, removed_stack.quantity)
		
		# Remettre le surplus si il y en a
		if surplus > 0:
			from_slot_obj.add_item(item, surplus)
		
		item_transferred.emit(from_container_id, to_container_id, item.id, quantity - surplus)
		return true
	
	return false

# === UTILITAIRES ===
func get_active_containers() -> Array[String]:
	return active_containers

func close_all_containers():
	for container_id in active_containers.duplicate():
		close_container(container_id)
