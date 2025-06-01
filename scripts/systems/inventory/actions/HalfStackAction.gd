# scripts/systems/inventory/actions/HalfStackAction.gd - VERSION CORRIGÉE
class_name HalfStackAction
extends BaseInventoryAction

func _init():
	super("half_stack", 1)  # PRIORITÉ 1 - Avant tout

func can_execute(context: ClickContext) -> bool:
	# Conditions strictes pour éviter les conflits
	var is_right_click = (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
	var source_not_empty = not context.source_slot_data.get("is_empty", true)
	var no_target = (context.target_slot_index == -1)
	var no_selection = not player_has_selection()
	
	return is_right_click and source_not_empty and no_target and no_selection

func execute(context: ClickContext) -> bool:
	print("\n🔄 [HALF-STACK] Traitement slot %d" % context.source_slot_index)
	
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
	
	print("📦 Item: %s, Quantité: %d" % [item.name, current_quantity])
	
	if current_quantity == 1:
		# Prendre tout si quantité = 1
		print("📦 Quantité = 1, prise complète")
		slot.clear()
		activate_hand_selection(item, 1)
	else:
		# Diviser le stack
		var half_to_take = current_quantity / 2
		var half_to_keep = current_quantity - half_to_take
		
		print("📊 Division: %d -> Garde %d, Prend %d" % [current_quantity, half_to_keep, half_to_take])
		
		# Mettre à jour le slot (garder la moitié)
		slot.item_stack.quantity = half_to_keep
		
		# Activer la sélection avec l'autre moitié
		activate_hand_selection(item, half_to_take)
	
	# Forcer les signaux et refresh
	slot.slot_changed.emit()
	controller.inventory.inventory_changed.emit()
	call_deferred("refresh_container_ui", context.source_container_id)
	
	print("✅ Half-stack réussi")
	return true
