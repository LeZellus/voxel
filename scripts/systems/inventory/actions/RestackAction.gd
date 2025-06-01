# scripts/systems/inventory/actions/RestackAction.gd - VERSION CORRIGÉE
class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 1)  # Priorité 1

func can_execute(context: ClickContext) -> bool:
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		return false
	
	# CAS 1: Main vers slot (source_slot_index = -1 quand créé depuis main)
	if context.source_slot_index == -1 and context.source_container_id == "player_hand":
		return _can_restack_from_hand_to_target(context)
	
	# CAS 2: Slot vers slot direct
	if context.target_slot_index != -1:
		return _can_restack_slots(context)
	
	return false

func execute(context: ClickContext) -> bool:
	print("\n📚 [RESTACK] Exécution...")
	
	if context.source_slot_index == -1 and context.source_container_id == "player_hand":
		return _execute_hand_to_slot_restack(context)
	else:
		return _execute_slot_to_slot_restack(context)

# === MÉTHODES DE VÉRIFICATION ===

func _can_restack_from_hand_to_target(context: ClickContext) -> bool:
	"""Vérifie si on peut restack depuis la main vers le slot target"""
	var hand_data = get_hand_data()
	
	# Le slot target est dans target_slot_data quand créé depuis HandPlacementAction
	var target_data = context.target_slot_data
	if target_data.is_empty():
		target_data = context.source_slot_data  # Fallback si mal configuré
	
	if target_data.get("is_empty", true):
		print("   ❌ Slot target vide")
		return false
	
	var hand_item_id = hand_data.get("item_id", "")
	var target_item_id = target_data.get("item_id", "")
	
	if hand_item_id != target_item_id or hand_item_id == "":
		print("   ❌ Items différents: %s vs %s" % [hand_item_id, target_item_id])
		return false
	
	# Vérifier stackability et espace
	var item_type = hand_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		print("   ❌ Outil non stackable")
		return false
	
	var target_qty = target_data.get("quantity", 0)
	var target_max = target_data.get("max_stack", 64)
	
	var has_space = target_qty < target_max
	print("   📊 Espace disponible: %d/%d = %s" % [target_qty, target_max, "✅" if has_space else "❌"])
	
	return has_space

func _can_restack_slots(context: ClickContext) -> bool:
	"""Vérifie si on peut restack entre deux slots"""
	if context.source_slot_data.get("is_empty", true) or context.target_slot_data.get("is_empty", true):
		return false
	
	var source_id = context.source_slot_data.get("item_id", "")
	var target_id = context.target_slot_data.get("item_id", "")
	
	if source_id != target_id or source_id == "":
		return false
	
	var item_type = context.source_slot_data.get("item_type", -1)
	if item_type == Item.ItemType.TOOL:
		return false
	
	var target_qty = context.target_slot_data.get("quantity", 0)
	var target_max = context.target_slot_data.get("max_stack", 64)
	
	return target_qty < target_max

# === MÉTHODES D'EXÉCUTION ===

func _execute_hand_to_slot_restack(context: ClickContext) -> bool:
	"""Exécute un restack depuis la main vers un slot"""
	print("   📚 Restack main → slot")
	
	var integrator = get_integrator()
	if not integrator:
		print("   ❌ Integrator introuvable")
		return false
	
	# Récupérer le slot target (peut être dans target_slot_index OU source_slot_index)
	var target_slot_index = context.target_slot_index
	var target_container_id = context.target_container_id
	
	if target_slot_index == -1:
		# Cas où le target est dans source (HandPlacementAction)
		target_slot_index = context.source_slot_index
		target_container_id = context.source_container_id
	
	var target_controller = get_controller(target_container_id)
	if not target_controller:
		print("   ❌ Controller target introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(target_slot_index)
	if not target_slot:
		print("   ❌ Slot target introuvable")
		return false
	
	var hand_data = integrator.selected_slot_info.slot_data
	var hand_qty = hand_data.get("quantity", 0)
	var target_qty = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	
	var can_transfer = min(hand_qty, target_max - target_qty)
	
	print("   📊 Transfer: %d (main: %d, target: %d/%d)" % [can_transfer, hand_qty, target_qty, target_max])
	
	if can_transfer <= 0:
		print("   ❌ Impossible de transférer")
		return false
	
	# Effectuer le transfert
	target_slot.item_stack.quantity += can_transfer
	var remaining = hand_qty - can_transfer
	
	# Gérer le slot source s'il existe
	var hand_slot_index = integrator.selected_slot_info.get("slot_index", -1)
	var hand_container_id = integrator.selected_slot_info.get("container_id", "")
	
	if hand_slot_index != -1 and hand_container_id != "player_hand":
		var source_controller = get_controller(hand_container_id)
		if source_controller:
			var source_slot = source_controller.inventory.get_slot(hand_slot_index)
			if source_slot:
				if remaining > 0:
					source_slot.item_stack.quantity = remaining
				else:
					source_slot.clear()
				source_slot.slot_changed.emit()
	
	# Mettre à jour la sélection
	if remaining > 0:
		update_hand_quantity(remaining)
		print("   ✅ Stack partiel: +%d, reste %d en main" % [can_transfer, remaining])
	else:
		clear_hand_selection()
		print("   ✅ Stack complet: +%d" % can_transfer)
	
	# Signaux
	target_slot.slot_changed.emit()
	target_controller.inventory.inventory_changed.emit()
	
	return true

func _execute_slot_to_slot_restack(context: ClickContext) -> bool:
	"""Exécute un restack entre deux slots"""
	print("   📚 Restack slot → slot")
	
	var source_ctrl = get_controller(context.source_container_id)
	var target_ctrl = get_controller(context.target_container_id)
	
	if not source_ctrl or not target_ctrl:
		print("   ❌ Controllers introuvables")
		return false
	
	var source_slot = source_ctrl.inventory.get_slot(context.source_slot_index)
	var target_slot = target_ctrl.inventory.get_slot(context.target_slot_index)
	
	if not source_slot or not target_slot:
		print("   ❌ Slots introuvables")
		return false
	
	var source_qty = source_slot.get_quantity()
	var target_qty = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	
	var can_transfer = min(source_qty, target_max - target_qty)
	
	print("   📊 Transfer: %d (source: %d, target: %d/%d)" % [can_transfer, source_qty, target_qty, target_max])
	
	if can_transfer <= 0:
		print("   ❌ Impossible de transférer")
		return false
	
	# Effectuer le transfert
	source_slot.item_stack.quantity -= can_transfer
	target_slot.item_stack.quantity += can_transfer
	
	# Nettoyer si vide
	if source_slot.get_quantity() <= 0:
		source_slot.clear()
	
	# Signaux
	source_slot.slot_changed.emit()
	target_slot.slot_changed.emit()
	source_ctrl.inventory.inventory_changed.emit()
	target_ctrl.inventory.inventory_changed.emit()
	
	print("   ✅ Transfer réussi: %d items" % can_transfer)
	return true
