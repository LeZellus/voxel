# scripts/systems/inventory/actions/RestackAction.gd - VERSION FINALE CORRIGÉE
class_name RestackAction
extends BaseInventoryAction

func _init():
	super("restack", 1)  # PRIORITÉ LA PLUS HAUTE

func can_execute(context: ClickContext) -> bool:
	"""
	Active pour regrouper des stacks identiques dans TOUS les cas
	"""
	print("\n🔍 === RESTACKACTION.CAN_EXECUTE ===")
	print("   - Type de clic: %s" % ClickContext.ClickType.keys()[context.click_type])
	
	if context.click_type != ClickContext.ClickType.SIMPLE_LEFT_CLICK:
		print("❌ Pas un clic gauche")
		return false
	
	# CAS 1: Item en main → slot cliqué
	if player_has_selection():
		print("📋 CAS 1: Item en main → slot cliqué")
		var result = _can_execute_hand_to_slot(context)
		print("   Résultat: %s" % ("✅" if result else "❌"))
		return result
	
	# CAS 2: Slot sélectionné → slot cliqué (avec target_slot_index != -1)
	if context.target_slot_index != -1:
		print("📋 CAS 2: Slot → slot cliqué")
		var result = _can_execute_slot_to_slot(context)
		print("   Résultat: %s" % ("✅" if result else "❌"))
		return result
	
	print("❌ Aucun cas applicable")
	return false

func _can_execute_hand_to_slot(context: ClickContext) -> bool:
	"""Vérifie si on peut faire un restack main → slot"""
	var clicked_slot_index = context.source_slot_index
	var clicked_slot_data = context.source_slot_data
	
	print("   - Slot cliqué: %d" % clicked_slot_index)
	print("   - Slot vide: %s" % clicked_slot_data.get("is_empty", true))
	
	if clicked_slot_index == -1 or clicked_slot_data.get("is_empty", true):
		print("   ❌ Slot invalide ou vide")
		return false
	
	var hand_data = get_hand_data()
	var hand_item_id = hand_data.get("item_id", "")
	var clicked_item_id = clicked_slot_data.get("item_id", "")
	
	print("   - Item en main: %s" % hand_item_id)
	print("   - Item cliqué: %s" % clicked_item_id)
	
	if hand_item_id != clicked_item_id or hand_item_id == "":
		print("   ❌ Items différents ou main vide")
		return false
	
	var hand_item_type = hand_data.get("item_type", -1)
	if hand_item_type == Item.ItemType.TOOL:
		print("   ❌ Outil non stackable")
		return false
	
	print("   ✅ Restack main→slot possible pour %s" % hand_item_id)
	return true

func _can_execute_slot_to_slot(context: ClickContext) -> bool:
	"""Vérifie si on peut faire un restack slot → slot"""
	var source_slot_data = context.source_slot_data
	var target_slot_data = context.target_slot_data
	
	print("   - Source vide: %s" % source_slot_data.get("is_empty", true))
	print("   - Target vide: %s" % target_slot_data.get("is_empty", true))
	
	# Les deux slots doivent avoir des items
	if source_slot_data.get("is_empty", true) or target_slot_data.get("is_empty", true):
		print("   ❌ Un des slots est vide")
		return false
	
	var source_item_id = source_slot_data.get("item_id", "")
	var target_item_id = target_slot_data.get("item_id", "")
	
	print("   - Item source: %s" % source_item_id)
	print("   - Item target: %s" % target_item_id)
	
	# Même item seulement
	if source_item_id != target_item_id or source_item_id == "":
		print("   ❌ Items différents")
		return false
	
	var source_item_type = source_slot_data.get("item_type", -1)
	if source_item_type == Item.ItemType.TOOL:
		print("   ❌ Outil non stackable")
		return false
	
	print("   ✅ Restack slot→slot possible pour %s" % source_item_id)
	return true

func execute(context: ClickContext) -> bool:
	"""Exécute le restack selon le cas"""
	print("\n🚀 === RESTACKACTION.EXECUTE ===")
	
	if player_has_selection():
		print("📋 Exécution: Main → Slot")
		return _execute_hand_to_slot(context)
	else:
		print("📋 Exécution: Slot → Slot")
		return _execute_slot_to_slot(context)

func _execute_hand_to_slot(context: ClickContext) -> bool:
	"""Restack depuis la main vers le slot cliqué - VERSION CORRIGÉE"""
	print("\n🔄 [ACTION] Restack Main → Slot %d" % context.source_slot_index)
	
	var hand_data = get_hand_data()
	var hand_quantity = hand_data.get("quantity", 0)
	var hand_item_id = hand_data.get("item_id", "")
	
	print("   - Main: %s x%d" % [hand_item_id, hand_quantity])
	
	# CORRECTION CRUCIALE: Utiliser le slot cliqué, pas le slot source
	var target_controller = get_controller(context.source_container_id)
	if not target_controller:
		print("❌ Controller target introuvable")
		return false
	
	var target_slot = target_controller.inventory.get_slot(context.source_slot_index)
	if not target_slot or target_slot.is_empty():
		print("❌ Slot target invalide")
		return false
	
	if target_slot.get_item().id != hand_item_id:
		print("❌ Items différents")
		return false
	
	# ÉTAT AVANT
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	print("📊 AVANT - Target: %d/%d (espace: %d), Main: %d" % [target_current, target_max, available_space, hand_quantity])
	
	if available_space <= 0:
		print("❌ Slot cible déjà plein")
		return false
	
	var can_transfer = min(hand_quantity, available_space)
	var remaining_in_hand = hand_quantity - can_transfer
	
	print("🔄 Transfert: %d items, reste: %d" % [can_transfer, remaining_in_hand])
	
	# EFFECTUER LE TRANSFERT ATOMIQUE
	target_slot.item_stack.quantity += can_transfer
	
	# FORCER LES SIGNAUX - CRUCIAL
	target_slot.slot_changed.emit()
	target_controller.inventory.inventory_changed.emit()
	
	print("📊 APRÈS - Target: %d, Main restante: %d" % [target_slot.get_quantity(), remaining_in_hand])
	
	if remaining_in_hand > 0:
		update_hand_quantity(remaining_in_hand)
	else:
		clear_hand_selection()
	
	# FORCER REFRESH UI IMMÉDIAT
	_force_refresh_ui(context.source_container_id)
	
	print("✅ Restack Main→Slot: %d transférés, %d restants" % [can_transfer, remaining_in_hand])
	return true

func _execute_slot_to_slot(context: ClickContext) -> bool:
	"""Restack entre deux slots - VERSION CORRIGÉE"""
	print("\n🔄 [ACTION] Restack Slot %d → Slot %d" % [context.source_slot_index, context.target_slot_index])
	
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
	
	if source_slot.is_empty() or target_slot.is_empty():
		print("❌ Un slot est vide")
		return false
	
	if source_slot.get_item().id != target_slot.get_item().id:
		print("❌ Items différents")
		return false
	
	# ÉTAT AVANT
	var source_quantity = source_slot.get_quantity()
	var target_current = target_slot.get_quantity()
	var target_max = target_slot.get_max_stack_size()
	var available_space = target_max - target_current
	
	print("📊 AVANT - Source: %d, Target: %d/%d (espace: %d)" % [source_quantity, target_current, target_max, available_space])
	
	if available_space <= 0:
		print("❌ Slot cible déjà plein")
		return false
	
	var can_transfer = min(source_quantity, available_space)
	var remaining_in_source = source_quantity - can_transfer
	
	print("🔄 Transfert: %d items, reste: %d" % [can_transfer, remaining_in_source])
	
	# EFFECTUER LE TRANSFERT ATOMIQUE
	target_slot.item_stack.quantity += can_transfer
	
	if remaining_in_source > 0:
		source_slot.item_stack.quantity = remaining_in_source
	else:
		source_slot.clear()
	
	# FORCER TOUS LES SIGNAUX - CRUCIAL
	source_slot.slot_changed.emit()
	target_slot.slot_changed.emit()
	source_controller.inventory.inventory_changed.emit()
	
	if context.source_container_id != context.target_container_id:
		target_controller.inventory.inventory_changed.emit()
	
	print("📊 APRÈS - Source: %d, Target: %d" % [
		source_slot.get_quantity() if not source_slot.is_empty() else 0,
		target_slot.get_quantity()
	])
	
	# FORCER REFRESH UI IMMÉDIAT
	_force_refresh_ui(context.source_container_id)
	if context.source_container_id != context.target_container_id:
		_force_refresh_ui(context.target_container_id)
	
	print("✅ Restack Slot→Slot: %d transférés, %d restants en source" % [can_transfer, remaining_in_source])
	return true

func _force_refresh_ui(container_id: String):
	"""Force le rafraîchissement UI immédiat et synchrone"""
	print("🔄 Force refresh UI pour: %s" % container_id)
	
	# Méthode 1: Via InventorySystem
	var inventory_system = ServiceLocator.get_service("inventory")
	if inventory_system:
		var container = inventory_system.get_container(container_id)
		if container and container.ui:
			if container.ui.has_method("refresh_ui"):
				container.ui.refresh_ui()
				print("  ✅ UI rafraîchie via container")
				return
	
	# Méthode 2: Recherche directe dans la scène
	var current_scene = Engine.get_main_loop().current_scene
	if current_scene:
		var ui_nodes = _find_inventory_uis(current_scene)
		for ui in ui_nodes:
			if ui.has_method("refresh_ui"):
				ui.refresh_ui()
				print("  ✅ UI rafraîchie via recherche directe")

func _find_inventory_uis(node: Node) -> Array:
	"""Trouve toutes les UIs d'inventaire dans la scène"""
	var uis = []
	
	if node.get_script():
		var script_name = node.get_script().get_global_name()
		if script_name in ["BaseInventoryUI", "MainInventoryUI", "HotbarUI"]:
			uis.append(node)
	
	for child in node.get_children():
		uis.append_array(_find_inventory_uis(child))
	
	return uis
