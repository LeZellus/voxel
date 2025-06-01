class_name HalfStackAction
extends BaseInventoryAction

func _init():
	super("half_stack", 2)  # PRIORITÉ 2 - Avant SimpleUseAction

func can_execute(context: ClickContext) -> bool:
	"""
	Active quand :
	- Clic droit sur un slot
	- Le slot n'est pas vide
	- Pas de slot cible (pas un transfert)
	- Le joueur n'a rien en main (pas de sélection active)
	- NOUVEAU: Quantité > 1 (sinon pas de sens)
	"""
	var is_right_click = (context.click_type == ClickContext.ClickType.SIMPLE_RIGHT_CLICK)
	var source_not_empty = not context.source_slot_data.get("is_empty", true)
	var no_target = (context.target_slot_index == -1)
	var no_selection = not player_has_selection()
	var quantity = context.source_slot_data.get("quantity", 1)
	
	var result = is_right_click and source_not_empty and no_target and no_selection and quantity > 1
	
	if result:
		print("🔍 HalfStackAction: ✅ Peut exécuter (quantité: %d)" % quantity)
	else:
		print("🔍 HalfStackAction: ❌ Ne peut pas exécuter")
		print("     - Clic droit: %s" % is_right_click)
		print("     - Source pas vide: %s" % source_not_empty)
		print("     - Pas de target: %s" % no_target)
		print("     - Pas de sélection: %s" % no_selection)
		print("     - Quantité > 1: %s (%d)" % [quantity > 1, quantity])
	
	return result

func execute(context: ClickContext) -> bool:
	"""Exécute la prise de moitié"""
	print("\n🔄 [ACTION] Prise de moitié du slot %d" % context.source_slot_index)
	
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
	
	print("📦 Item: %s, Quantité actuelle: %d" % [item.name, current_quantity])
	
	if current_quantity <= 1:
		print("⚠️ Quantité = 1, prise complète")
		return _take_full_stack(slot, item, current_quantity)
	
	# Calculer la moitié
	var half_to_take = current_quantity / 2  # Division entière
	var half_to_keep = current_quantity - half_to_take
	
	print("📊 Division: %d -> Garde %d, Prend %d" % [current_quantity, half_to_keep, half_to_take])
	
	# Mettre à jour le slot source
	slot.item_stack.quantity = half_to_keep
	slot.slot_changed.emit()
	
	# Activer la sélection avec la moitié prise
	activate_hand_selection(item, half_to_take)
	
	# Forcer refresh UI
	call_deferred("refresh_container_ui", context.source_container_id)
	
	print("✅ Half-stack réussi: Garde %d, En main %d" % [half_to_keep, half_to_take])
	return true

func _take_full_stack(slot, item: Item, quantity: int) -> bool:
	"""Prend tout le stack (cas spécial pour quantité 1)"""
	print("📦 Prise complète de: %s x%d" % [item.name, quantity])
	
	# Vider le slot
	slot.clear()
	
	# Activer la sélection avec tout l'item
	activate_hand_selection(item, quantity)
	
	return true
