# scripts/systems/inventory/actions/RestackAction.gd - VERSION CORRIGÉE ET SIMPLIFIÉE
class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 1) # PRIORITÉ MAXIMALE

func can_execute(context: ClickContext) -> bool:
	"""
	CORRIGÉ: Gère maintenant AUSSI main → slot avec même item
	"""
	print("\n🔍 === RESTACKACTION.CAN.EXECUTE ===")
	
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		print("❌ Pas un clic gauche")
		return false
	
	# CAS 1: Slot-to-slot classique
	if context.target_slot_index != -1:
		return _can_execute_slot_to_slot(context)
	
	# CAS 2: NOUVEAU - Main-to-slot avec même item (restack depuis main)
	if player_has_selection():
		return _can_execute_hand_to_slot_restack(context)
	
	print("❌ Ni slot-to-slot ni restack depuis main")
	return false

func execute(context: ClickContext) -> bool:
	"""Exécute selon le type de restack"""
	print("\n🚀 === RESTACKACTION.EXECUTE ===")
	
	if context.target_slot_index != -1:
		return _execute_slot_to_slot_restack(context)
	else:
		return _execute_hand_to_slot_restack(context)
		
func _execute_atomic_transfer(source_slot, target_slot, transfer_amount: int) -> bool:
	"""Effectue le transfert de manière atomique"""
	
	# Sauvegarder l'état avant modification (si nécessaire pour un "rollback")
	# GDScript n'a pas de try/except, donc la "restauration" doit être gérée manuellement
	# Ici, nous allons juste valider en amont et si une condition n'est pas remplie,
	# nous retournons false avant de modifier quoi que ce soit.
	
	var source_original_qty = source_slot.get_quantity()
	var target_original_qty = target_slot.get_quantity()
	
	# Validation finale
	if transfer_amount <= 0 or transfer_amount > source_original_qty:
		print("❌ Quantité de transfert invalide: %d" % transfer_amount)
		return false
	
	# Modifier target en premier
	target_slot.item_stack.quantity += transfer_amount
	
	# Modifier source
	var new_source_qty = source_original_qty - transfer_amount
	if new_source_qty > 0:
		source_slot.item_stack.quantity = new_source_qty
	else:
		source_slot.clear() # Ou définissez explicitement la pile d'objets comme vide
	
	# Si toutes les opérations ci-dessus se sont déroulées sans "erreur" (selon nos checks),
	# alors le transfert est considéré comme réussi.
	print("✅ Transfert atomique réussi")
	return true

func _force_signals_and_refresh(source_controller, target_controller, context: ClickContext):
	"""Force l'émission des signaux et le refresh des UIs"""
	
	# Émettre les signaux de slot
	var source_slot = source_controller.inventory.get_slot(context.source_slot_index)
	var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
	
	if source_slot:
		source_slot.slot_changed.emit()
	if target_slot:
		target_slot.slot_changed.emit()
	
	# Émettre les signaux d'inventaire
	source_controller.inventory.inventory_changed.emit()
	if context.source_container_id != context.target_container_id:
		target_controller.inventory.inventory_changed.emit()
	
	# Forcer refresh UI avec délai
	call_deferred("_delayed_refresh", context)

func _delayed_refresh(context: ClickContext):
	"""Refresh différé des UIs"""
	refresh_container_ui(context.source_container_id)
	if context.source_container_id != context.target_container_id:
		refresh_container_ui(context.target_container_id)

func _get_max_stack_size(slot_data: Dictionary) -> int:
	"""Récupère la taille max du stack depuis les données"""
	return slot_data.get("max_stack", 64) # Valeur par défaut
	
func _execute_hand_to_slot_restack(context: ClickContext) -> bool:
	"""NOUVEAU: Exécute restack depuis main vers slot"""
	print("    - Restack: main → slot %d" % context.source_slot_index)
	
	var hand_data = get_hand_data()
	var hand_quantity = hand_data.get("quantity", 0)
	
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		print("❌ Controller introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot:
		print("❌ Slot target introuvable")
		return false
	
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	var can_transfer = min(hand_quantity, available_space)
	var remaining_in_hand = hand_quantity - can_transfer
	
	print("📊 Transfert: %d items, reste en main: %d" % [can_transfer, remaining_in_hand])
	
	# Effectuer le transfert
	target_slot.item_stack.quantity += can_transfer
	
	if remaining_in_hand > 0:
		update_hand_quantity(remaining_in_hand)
	else:
		clear_hand_selection()
	
	# Forcer signaux et refresh
	target_slot.slot_changed.emit()
	target_controller.inventory.inventory_changed.emit()
	call_deferred("refresh_container_ui", context.source_container_id)
	
	print("✅ Restack main→slot réussi")
	return true
	
func _can_execute_hand_to_slot_restack(context: ClickContext) -> bool:
	"""NOUVEAU: Logique main-to-slot avec même item"""
	var hand_data = get_hand_data()
	var slot_data = context.source_slot_data
	
	# Vérifier que le slot n'est pas vide
	if slot_data.get("is_empty", true):
		print("❌ Slot cible vide - pas un restack")
		return false
	
	# Vérifier même item
	var hand_item_id = hand_data.get("item_id", "")
	var slot_item_id = slot_data.get("item_id", "")
	
	if hand_item_id != slot_item_id or hand_item_id == "":
		print("❌ Items différents main:%s vs slot:%s" % [hand_item_id, slot_item_id])
		return false
	
	# Vérifier stackable
	var item_type = hand_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		print("❌ Item non stackable (outil)")
		return false
	
	# Vérifier qu'il y a de la place
	var slot_quantity = slot_data.get("quantity", 0)
	var slot_max = _get_max_stack_size(slot_data)
	
	if slot_quantity >= slot_max:
		print("❌ Slot déjà plein (%d/%d)" % [slot_quantity, slot_max])
		return false
	
	print("✅ Restack main→slot possible: %s" % hand_item_id)
	return true
	
func _can_execute_slot_to_slot(context: ClickContext) -> bool:
	"""Logique slot-to-slot existante"""
	var source_empty = context.source_slot_data.get("is_empty", true)
	var target_empty = context.target_slot_data.get("is_empty", true)
	
	if source_empty or target_empty:
		print("❌ Un des slots est vide (source: %s, target: %s)" % [source_empty, target_empty])
		return false
	
	var source_item_id = context.source_slot_data.get("item_id", "")
	var target_item_id = context.target_slot_data.get("item_id", "")
	
	if source_item_id != target_item_id or source_item_id == "":
		print("❌ Items différents (source: %s, target: %s)" % [source_item_id, target_item_id])
		return false
	
	var item_type = context.source_slot_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		print("❌ Item non stackable (outil)")
		return false
	
	var target_quantity = context.target_slot_data.get("quantity", 0)
	var target_max = _get_max_stack_size(context.target_slot_data)
	
	if target_quantity >= target_max:
		print("❌ Slot target déjà plein (%d/%d)" % [target_quantity, target_max])
		return false
	
	print("✅ Restack slot→slot possible")
	return true

func _execute_slot_to_slot_restack(context: ClickContext) -> bool:
	"""Exécute le restack slot → slot (code existant)"""
	print("    - Restack: %s[%d] → %s[%d]" % [
		context.source_container_id, context.source_slot_index,
		context.target_container_id, context.target_slot_index
	])
	
	# Utiliser le code existant de l'ancien execute()
	var source_controller = get_controller(context.source_container_id)
	var target_controller = get_controller(context.target_container_id)
	
	if not source_controller or not target_controller:
		print("❌ Controllers introuvables")
		return false
	
	var source_slot = source_controller.inventory.get_slot(context.source_slot_index)
	var target_slot = target_controller.inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		print("❌ Slots introuvables")
		return false
	
	var source_quantity = source_slot.get_quantity()
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	var can_transfer = min(source_quantity, available_space)
	var remaining_in_source = source_quantity - can_transfer
	
	print("📊 Transfert: %d items, reste en source: %d" % [can_transfer, remaining_in_source])
	
	if not _execute_atomic_transfer(source_slot, target_slot, can_transfer):
		return false
	
	_force_signals_and_refresh(source_controller, target_controller, context)
	return true
