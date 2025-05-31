# scripts/click_system/actions/UseItemAction.gd
class_name UseItemAction
extends ClickAction

var system_manager: ClickSystemManager

func _init(manager: ClickSystemManager):
	system_manager = manager
	action_name = "use_item"
	can_undo = false  # L'utilisation d'items n'est généralement pas réversible

func can_execute(context: ClickContext) -> bool:
	print("🔍 UseItemAction.can_execute() - Debug")
	print("   - target_slot_index: %d" % context.target_slot_index)
	print("   - source_slot_data: %s" % context.source_slot_data)
	
	# Cette action ne fonctionne que sur des clics simples avec un item
	if context.target_slot_index != -1:
		print("   - Rejeté: target_slot_index != -1")
		return false  # Pas d'action slot-to-slot pour "use"
	
	if not validate_source_slot(context):
		print("   - Rejeté: validate_source_slot failed")
		return false
	
	if not validate_has_source_item(context):
		print("   - Rejeté: validate_has_source_item failed")
		return false
	
	# Vérifier que l'item est utilisable
	var item_type = context.source_slot_data.get("item_type", -1)
	var usable = _is_item_usable(item_type)
	print("   - item_type: %d, usable: %s" % [item_type, usable])
	
	return usable

func _is_item_usable(item_type) -> bool:
	"""Détermine si un type d'item est utilisable"""
	if item_type == -1:
		return false
	
	# Utiliser l'enum Item.ItemType
	match item_type:
		Item.ItemType.CONSUMABLE:
			return true
		Item.ItemType.TOOL:
			return true  # Les outils peuvent être "équipés"
		Item.ItemType.RESOURCE:
			return false  # Les ressources ne sont pas directement utilisables
		Item.ItemType.EQUIPMENT:
			return true  # Les équipements peuvent être équipés
		_:
			return false

func execute(context: ClickContext) -> bool:
	log_action(context, "Utilisation de l'item")
	
	var controller = get_source_controller(context, system_manager)
	if not controller:
		log_action(context, "Contrôleur introuvable")
		emit_action_signals(context, false)
		return false
	
	var item_type = context.source_slot_data.get("item_type", -1)
	var item_id = context.source_slot_data.get("item_id", "")
	var item_name = context.source_slot_data.get("item_name", "")
	
	var success = false
	
	match item_type:
		Item.ItemType.CONSUMABLE:
			success = _use_consumable(context, controller, item_id, item_name)
		
		Item.ItemType.TOOL:
			success = _equip_tool(context, controller, item_id, item_name)
		
		Item.ItemType.EQUIPMENT:
			success = _equip_item(context, controller, item_id, item_name)
		
		_:
			log_action(context, "Type d'item non supporté: %s" % str(item_type))
			success = false
	
	emit_action_signals(context, success)
	return success

func _use_consumable(context: ClickContext, controller: RefCounted, item_id: String, item_name: String) -> bool:
	"""Utilise un objet consommable"""
	log_action(context, "Consommation de: %s" % item_name)
	
	# Retirer 1 quantité de l'inventaire
	var removed = controller.remove_item(item_id, 1)
	
	if removed > 0:
		# Ici on pourrait ajouter des effets spécifiques selon l'item
		_apply_consumable_effect(item_id, item_name)
		log_action(context, "✅ %s consommé" % item_name)
		return true
	else:
		log_action(context, "❌ Impossible de consommer %s" % item_name)
		return false

func _equip_tool(context: ClickContext, controller: RefCounted, item_id: String, item_name: String) -> bool:
	"""Équipe un outil"""
	log_action(context, "Équipement de l'outil: %s" % item_name)
	
	# Pour l'instant, juste un message - plus tard on ajoutera la logique d'équipement
	print("🔨 Outil équipé: %s" % item_name)
	
	# Émettre un signal pour notifier le système d'équipement
	if system_manager.has_signal("tool_equipped"):
		system_manager.emit_signal("tool_equipped", item_id, item_name, context.source_container_id)
	
	return true

func _equip_item(context: ClickContext, controller: RefCounted, item_id: String, item_name: String) -> bool:
	"""Équipe un équipement"""
	log_action(context, "Équipement de: %s" % item_name)
	
	# Pour l'instant, juste un message - plus tard on ajoutera la logique d'équipement
	print("⚔️ Équipement équipé: %s" % item_name)
	
	# Émettre un signal pour notifier le système d'équipement
	if system_manager.has_signal("equipment_equipped"):
		system_manager.emit_signal("equipment_equipped", item_id, item_name, context.source_container_id)
	
	return true

func _apply_consumable_effect(item_id: String, item_name: String):
	"""Applique l'effet d'un consommable"""
	# Effets par défaut selon l'ID de l'item
	match item_id:
		"apple", "test_item_0":
			print("🍎 %s consommé - PV restaurés !" % item_name)
			# Ici on pourrait restaurer des PV du joueur
		
		"potion_health":
			print("🧪 %s consommé - Soins majeurs !" % item_name)
			# Ici on pourrait restaurer beaucoup de PV
		
		"potion_mana":
			print("💙 %s consommé - Mana restauré !" % item_name)
			# Ici on pourrait restaurer du mana
		
		_:
			print("🤷 %s consommé - Effet inconnu" % item_name)

func get_description(context: ClickContext) -> String:
	var item_name = context.source_slot_data.get("item_name", "objet")
	var item_type = context.source_slot_data.get("item_type", -1)
	
	match item_type:
		Item.ItemType.CONSUMABLE:
			return "Consommer: %s" % item_name
		Item.ItemType.TOOL:
			return "Équiper l'outil: %s" % item_name
		Item.ItemType.EQUIPMENT:
			return "Équiper: %s" % item_name
		_:
			return "Utiliser: %s" % item_name

func get_feedback_message(context: ClickContext, success: bool) -> String:
	var item_name = context.source_slot_data.get("item_name", "objet")
	
	if success:
		return "%s utilisé avec succès" % item_name
	else:
		return "Impossible d'utiliser %s" % item_name
