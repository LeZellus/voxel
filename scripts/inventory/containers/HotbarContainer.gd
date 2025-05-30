# scripts/inventory/containers/HotbarContainer.gd
class_name HotbarContainer
extends BaseContainer

signal item_selected(slot_index: int, item: Item)
signal hotbar_item_used(slot_index: int, item: Item)

const HOTBAR_SIZE = 9
var selected_slot: int = 0

func _init():
	super(
		"player_hotbar", 
		HOTBAR_SIZE, 
		"Barre d'Action",
		"res://scenes/ui/HotbarUI.tscn"
	)

func _ready():
	print("🔧 HotbarContainer _ready() démarré")
	
	# Setup de l'UI automatique
	var success = await setup_ui()
	if success:
		print("✅ Hotbar UI setup réussi")
		await _setup_ui_hotbar()
	else:
		print("❌ Erreur lors de l'initialisation de HotbarContainer")

func _setup_ui_hotbar():
	"""Configure l'UI avec l'inventaire et le contrôleur"""
	if not ui:
		print("❌ UI non disponible pour setup hotbar")
		return
	
	if not ui.has_method("setup_hotbar"):
		print("❌ UI n'a pas la méthode setup_hotbar")
		return
	
	print("🔧 Configuration de la Hotbar UI")
	ui.setup_hotbar(inventory, controller, self)
	
	ui.visible = true
	ui.show()
	is_open = true
	
	# Sélectionner le premier slot par défaut
	select_slot(0)
	
func show_ui():
	"""Override: La hotbar est toujours visible, pas d'animation"""
	if not ui:
		print("❌ Pas d'UI à afficher pour la hotbar")
		return
	
	print("🎯 Affichage permanent de la hotbar")
	ui.visible = true
	ui.show()
	is_open = true
	
	# Pas d'animation ni de son pour la hotbar
	_on_container_opened()

# === API HOTBAR SPÉCIFIQUE ===

func select_slot(slot_index: int):
	"""Sélectionne un slot de la hotbar"""
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return
	
	selected_slot = slot_index
	
	# Mettre à jour l'UI
	if ui and ui.has_method("set_selected_slot"):
		ui.set_selected_slot(selected_slot)
	
	# Émettre le signal avec l'item sélectionné
	var slot = inventory.get_slot(selected_slot)
	if slot and not slot.is_empty():
		item_selected.emit(selected_slot, slot.get_item())
	else:
		item_selected.emit(selected_slot, null)

func get_selected_slot() -> int:
	return selected_slot

func get_selected_item() -> Item:
	"""Retourne l'item actuellement sélectionné"""
	var slot = inventory.get_slot(selected_slot)
	if slot and not slot.is_empty():
		return slot.get_item()
	return null

func use_selected_item() -> bool:
	"""Utilise l'item sélectionné"""
	var slot = inventory.get_slot(selected_slot)
	if slot and not slot.is_empty():
		var item = slot.get_item()
		
		# Pour l'instant, on ne fait que retirer 1 quantité
		# Plus tard on ajoutera la logique d'utilisation selon le type d'item
		var removed = slot.remove_item(1)
		
		if removed.quantity > 0:
			hotbar_item_used.emit(selected_slot, item)
			_play_ui_sound("item_use")
			print("🎯 Item utilisé: %s" % item.name)
			return true
	
	return false

func select_next_slot():
	"""Sélectionne le slot suivant (pour la molette)"""
	var next_slot = (selected_slot + 1) % HOTBAR_SIZE
	select_slot(next_slot)

func select_previous_slot():
	"""Sélectionne le slot précédent (pour la molette)"""
	var prev_slot = (selected_slot - 1 + HOTBAR_SIZE) % HOTBAR_SIZE
	select_slot(prev_slot)

# === RACCOURCIS CLAVIER ===

func handle_number_key(number: int):
	"""Gère les touches 1-9 pour sélectionner les slots"""
	if number >= 1 and number <= HOTBAR_SIZE:
		select_slot(number - 1)  # Les touches 1-9 correspondent aux slots 0-8

# === INTÉGRATION AVEC L'INVENTAIRE PRINCIPAL ===

func can_accept_from_inventory(item: Item, quantity: int = 1) -> bool:
	"""Vérifie si on peut accepter un item depuis l'inventaire principal"""
	return true  # La hotbar accepte tous les items pour l'instant

func transfer_from_inventory(source_inventory: Inventory, source_slot: int, target_slot: int) -> bool:
	"""Transfère un item depuis l'inventaire principal vers la hotbar"""
	if target_slot < 0 or target_slot >= HOTBAR_SIZE:
		return false
	
	var source_slot_obj = source_inventory.get_slot(source_slot)
	var target_slot_obj = inventory.get_slot(target_slot)
	
	if source_slot_obj.is_empty():
		return false
	
	var item = source_slot_obj.get_item()
	var quantity = source_slot_obj.get_quantity()
	
	# Logique de transfert (swap ou stack)
	if target_slot_obj.is_empty():
		# Slot vide : déplacer tout
		var removed = source_slot_obj.remove_item(quantity)
		target_slot_obj.add_item(removed.item, removed.quantity)
		return true
	elif target_slot_obj.can_accept_item(item, quantity):
		# Stackable : ajouter
		var removed = source_slot_obj.remove_item(quantity)
		var surplus = target_slot_obj.add_item(removed.item, removed.quantity)
		if surplus > 0:
			source_slot_obj.add_item(removed.item, surplus)
		return true
	else:
		# Swap
		var temp_item = target_slot_obj.get_item()
		var temp_quantity = target_slot_obj.get_quantity()
		
		target_slot_obj.clear()
		target_slot_obj.add_item(item, quantity)
		
		source_slot_obj.clear()
		source_slot_obj.add_item(temp_item, temp_quantity)
		return true

# === OVERRIDE POUR COMPORTEMENT SPÉCIFIQUE ===

func _on_container_opened():
	"""La hotbar ne s'ouvre/ferme pas comme un inventaire normal"""
	pass

func _on_container_closed():
	"""La hotbar reste toujours visible"""
	pass

# === DEBUG ===

func debug_hotbar():
	print("\n🎯 DEBUG Hotbar:")
	print("   - Slot sélectionné: %d" % selected_slot)
	print("   - Item sélectionné: %s" % (get_selected_item().name if get_selected_item() else "aucun"))
	
	for i in HOTBAR_SIZE:
		var slot = inventory.get_slot(i)
		if slot and not slot.is_empty():
			print("   - Slot %d: %s x%d" % [i, slot.get_item().name, slot.get_quantity()])
		else:
			print("   - Slot %d: vide" % i)
