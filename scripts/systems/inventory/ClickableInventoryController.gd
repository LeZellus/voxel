# scripts/systems/inventory/ClickableInventoryController.gd - VERSION CORRIGÉE
class_name ClickableInventoryController
extends RefCounted

var inventory: Inventory

func _init(inv: Inventory):
	inventory = inv

func get_slot_info(slot_index: int) -> Dictionary:
	"""Version click-system qui inclut item_type"""
	var slot = inventory.get_slot(slot_index)
	if not slot:
		return {"is_empty": true, "index": slot_index}
	
	var info = {
		"index": slot.index,
		"is_empty": slot.is_empty()
	}
	
	if not slot.is_empty():
		var item = slot.get_item()
		if item:
			info.merge({
				"item_id": item.id,
				"item_name": item.name,
				"item_type": item.item_type,
				"quantity": slot.get_quantity(),
				"max_stack": item.max_stack_size,
				"icon": item.icon
			})
	
	return info

func move_item(from_slot: int, to_slot: int) -> bool:
	"""Déplace un item entre deux slots - VERSION CORRIGÉE"""
	print("🔧 [CONTROLLER] move_item(%d -> %d)" % [from_slot, to_slot])
	
	var from_slot_obj = inventory.get_slot(from_slot)
	var to_slot_obj = inventory.get_slot(to_slot)
	
	if not from_slot_obj or not to_slot_obj:
		print("❌ Slots introuvables: from=%s, to=%s" % [str(from_slot_obj), str(to_slot_obj)])
		return false
	
	if from_slot_obj.is_empty():
		print("❌ Slot source vide")
		return false
	
	if from_slot == to_slot:
		print("⚠️ Même slot, pas de déplacement")
		return false
	
	var item = from_slot_obj.get_item()
	var quantity = from_slot_obj.get_quantity()
	
	print("📦 Déplacement: %s x%d (slot %d -> %d)" % [item.name, quantity, from_slot, to_slot])
	
	# Slot de destination vide : déplacer tout
	if to_slot_obj.is_empty():
		print("✅ Destination vide - déplacement direct")
		
		# Créer un nouveau stack avec l'item source AVANT de le retirer
		var new_stack = ItemStack.new(item, quantity)
		
		# Retirer de la source
		var removed_stack = from_slot_obj.remove_item(quantity)
		print("📤 Retiré de source: %s x%d" % [removed_stack.item.name if removed_stack.item else "null", removed_stack.quantity])
		
		# Ajouter à la destination (avec les données sauvegardées)
		var surplus = to_slot_obj.add_item(new_stack.item, new_stack.quantity)
		print("📥 Ajouté à destination: surplus=%d" % surplus)
		
		if surplus > 0:
			# Remettre le surplus dans la source
			from_slot_obj.add_item(item, surplus)
			print("⚠️ Surplus remis en source: %d" % surplus)
		
		return true
	
	# Même item : essayer de stacker
	elif to_slot_obj.get_item().id == item.id and item.is_stackable:
		print("📚 Tentative de stack...")
		
		if to_slot_obj.can_accept_item(item, quantity):
			var removed_stack = from_slot_obj.remove_item(quantity)
			var surplus = to_slot_obj.add_item(item, removed_stack.quantity)
			
			if surplus > 0:
				from_slot_obj.add_item(item, surplus)
			
			print("✅ Stack réussi (surplus: %d)" % surplus)
			return true
		else:
			print("❌ Stack impossible - slot destination plein")
			return false
	
	# Items différents : swap
	else:
		print("🔄 Swap d'items différents...")
		
		var temp_item = to_slot_obj.get_item()
		var temp_qty = to_slot_obj.get_quantity()
		
		# Vider les deux slots
		to_slot_obj.clear()
		from_slot_obj.clear()
		
		# Échanger
		to_slot_obj.add_item(item, quantity)
		from_slot_obj.add_item(temp_item, temp_qty)
		
		print("✅ Swap réussi")
		return true

func remove_item(item_id: String, quantity: int = 1) -> int:
	"""Retire un item de l'inventaire"""
	return inventory.remove_item(item_id, quantity)
