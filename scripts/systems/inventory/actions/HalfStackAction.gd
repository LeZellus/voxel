# scripts/systems/inventory/actions/HalfStackAction.gd
class_name HalfStackAction
extends BaseInventoryAction

func _init():
	super("half_stack", 15)

func can_execute(context: ClickContext) -> bool:
	"""
	Active quand :
	- Clic droit sur un slot
	- Le slot n'est pas vide
	- Pas de slot cible (pas un transfert)
	- Le joueur n'a rien en main (pas de sélection active)
	"""
	return (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK 
			and not context.source_slot_data.get("is_empty", true)
			and context.target_slot_index == -1
			and not player_has_selection())

func execute(context: ClickContext) -> bool:
	"""Exécute la prise de moitié"""
	print("🔄 [ACTION] Prise de moitié du slot %d" % context.source_slot_index)
	
	var controller = get_controller(context.source_container_id)
	if not controller:
		print("❌ Controller introuvable")
		return false
	
	var slot = controller.inventory.get_slot(context.source_slot_index)
	if not slot or slot.is_empty():
		print("❌ Slot vide ou introuvable")
		return false
	
	var current_quantity = slot.get_quantity()
	var item = slot.get_item()
	
	if current_quantity <= 1:
		print("⚠️ Quantité = 1, prise complète")
		return _take_full_stack(slot, item, current_quantity)
	
	# Calculer la moitié
	var half_to_take = current_quantity / 2  # Division entière
	var half_to_keep = current_quantity - half_to_take
	
	print("📦 Division: %d -> Garde %d, Prend %d" % [current_quantity, half_to_keep, half_to_take])
	
	# Mettre à jour le slot source
	slot.item_stack.quantity = half_to_keep
	slot.slot_changed.emit()
	
	# Activer la sélection avec la moitié prise
	activate_hand_selection(item, half_to_take)
	
	return true

func _take_full_stack(slot, item: Item, quantity: int) -> bool:
	"""Prend tout le stack (cas spécial pour quantité 1)"""
	# Vider le slot
	slot.clear()
	
	# Activer la sélection avec tout l'item
	activate_hand_selection(item, quantity)
	
	return true
