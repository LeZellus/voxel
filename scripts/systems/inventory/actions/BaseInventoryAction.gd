# scripts/systems/inventory/actions/BaseInventoryAction.gd
class_name BaseInventoryAction
extends RefCounted

var name: String
var priority: int

func _init(action_name: String, action_priority: int = 0):
	name = action_name
	priority = action_priority

# Méthodes virtuelles à override
func can_execute(_context: ClickContext) -> bool:
	return false

func execute(_context: ClickContext) -> bool:
	return false

# === MÉTHODES UTILITAIRES COMMUNES ===

func player_has_selection() -> bool:
	"""Vérifie si le joueur a déjà quelque chose en main"""
	var integrator = get_integrator()
	return integrator and not integrator.selected_slot_info.is_empty()

func get_hand_data() -> Dictionary:
	"""Récupère les données de l'item en main"""
	var integrator = get_integrator()
	if integrator and not integrator.selected_slot_info.is_empty():
		return integrator.selected_slot_info.slot_data
	return {}

func get_controller(container_id: String):
	"""Récupère le controller d'un container"""
	var click_manager = get_click_manager()
	return click_manager.get_controller_for_container(container_id) if click_manager else null

func get_click_manager():
	"""Récupère le ClickSystemManager"""
	return ServiceLocator.get_service("click_system")

func get_integrator():
	"""Récupère le ClickSystemIntegrator"""
	var inventory_system = ServiceLocator.get_service("inventory")
	return inventory_system.get_click_integrator() if inventory_system else null

func clear_hand_selection():
	"""Vide complètement la sélection en main"""
	var integrator = get_integrator()
	if not integrator:
		return
	
	integrator.selected_slot_info.clear()
	integrator._hide_item_preview()
	
	# Nettoyer la sélection visuelle
	integrator._clear_visual_selection()
	integrator.currently_selected_slot_ui = null

func update_hand_quantity(new_quantity: int):
	"""Met à jour la quantité en main"""
	var integrator = get_integrator()
	if not integrator:
		return
	
	integrator.selected_slot_info.slot_data.quantity = new_quantity
	integrator._show_item_preview(integrator.selected_slot_info.slot_data)

func activate_hand_selection(item: Item, quantity: int):
	"""Active la sélection du joueur avec l'item donné"""
	var integrator = get_integrator()
	if not integrator:
		print("❌ Integrator introuvable")
		return
	
	# Simuler une sélection active
	integrator.selected_slot_info = {
		"slot_index": -1,  # -1 = en main
		"container_id": "player_hand",
		"slot_data": {
			"is_empty": false,
			"item_id": item.id,
			"item_name": item.name,
			"item_type": item.item_type,
			"quantity": quantity,
			"icon": item.icon
		}
	}
	
	# Afficher la preview
	integrator._show_item_preview(integrator.selected_slot_info.slot_data)
	
	print("✅ Sélection activée: %s x%d" % [item.name, quantity])

func refresh_container_ui(container_id: String):
	"""Rafraîchit l'UI d'un container"""
	var inventory_system = ServiceLocator.get_service("inventory")
	if not inventory_system:
		return
	
	var container = inventory_system.get_container(container_id)
	if container and container.ui and container.ui.has_method("refresh_ui"):
		container.ui.refresh_ui()

func create_item_from_data(item_data: Dictionary) -> Item:
	"""Crée un Item à partir des données"""
	var item = Item.new()
	item.id = item_data.get("item_id", "")
	item.name = item_data.get("item_name", "")
	item.item_type = item_data.get("item_type", Item.ItemType.RESOURCE)
	item.icon = item_data.get("icon")
	
	# Déterminer stackability basé sur le type
	match item.item_type:
		Item.ItemType.TOOL:
			item.max_stack_size = 1
			item.is_stackable = false
		Item.ItemType.CONSUMABLE, Item.ItemType.RESOURCE:
			item.max_stack_size = 64
			item.is_stackable = true
		_:
			item.max_stack_size = 1
			item.is_stackable = false
	
	return item
