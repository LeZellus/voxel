# scripts/ui/inventory/HotbarUI.gd - TOUJOURS CLIQUABLE
class_name HotbarUI
extends BaseInventoryUI

# === CONFIGURATION HOTBAR ===

func get_grid_columns() -> int:
	return 9

func get_max_slots() -> int:
	return 9

func should_show_title() -> bool:
	return true

func get_slot_size() -> Vector2:
	return Vector2(64, 64)

# === AFFICHAGE AVEC PRIORITÉ ===

func show_ui():
	"""Affiche la hotbar avec priorité d'affichage"""
	visible = true
	modulate.a = 1.0
	
	# CRUCIAL : S'assurer que la hotbar reste au premier plan
	_ensure_top_priority()
	
	print("📦 Hotbar affichée avec priorité")

func hide_ui():
	"""Cache la hotbar (normalement jamais appelé)"""
	visible = false
	print("📦 Hotbar cachée")

func _ensure_top_priority():
	"""S'assure que la hotbar reste au premier plan"""
	
	# Vérifier le parent CanvasLayer
	var parent = get_parent()
	if parent is CanvasLayer:
		var canvas_layer = parent as CanvasLayer
		canvas_layer.layer = 20  # Plus élevé que l'inventaire (10)
		print("🔝 Hotbar mise au premier plan (layer 20)")
	
	# S'assurer que tous les slots restent cliquables
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Forcer tous les enfants à être cliquables
	_force_children_clickable(self)

func _force_children_clickable(node: Node):
	"""Force récursivement tous les enfants à être cliquables"""
	
	if node is Control:
		var control = node as Control
		# Ne pas bloquer les interactions
		if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Assurer que les boutons restent interactifs
		if node is Button:
			var button = node as Button
			button.disabled = false
			button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Récursion sur les enfants
	for child in node.get_children():
		_force_children_clickable(child)

# === POSITIONNEMENT SÉCURISÉ ===

func _ready():
	super._ready()
	_setup_hotbar_position()
	
	# S'assurer que la hotbar reste toujours interactive
	_ensure_permanent_interactivity()

func _setup_hotbar_position():
	"""Positionne la hotbar en haut de l'écran"""
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	var margin_top = 4
	var new_position = Vector2(
		(viewport_size.x - size.x) / 2, 
		margin_top
	)
	
	position = new_position
	print("📍 Hotbar positionnée: %s" % new_position)

func _ensure_permanent_interactivity():
	"""S'assure que la hotbar reste interactive en permanence"""
	
	# Se connecter aux changements de scène pour maintenir la priorité
	get_tree().node_added.connect(_on_node_added)
	
	# Timer pour vérifier périodiquement
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_periodic_priority_check)
	timer.autostart = true
	add_child(timer)
	
	print("⚡ Hotbar : interactivité permanente activée")

func _on_node_added(node: Node):
	"""Callback quand un nouveau node est ajouté à la scène"""
	
	# Si c'est une UI d'inventaire, s'assurer qu'on reste au premier plan
	if node.name.contains("Inventory") or node.name.contains("MainInventory"):
		call_deferred("_ensure_top_priority")

func _periodic_priority_check():
	"""Vérification périodique de la priorité"""
	
	if visible:
		_ensure_top_priority()

# === OVERRIDE POUR DEBUG ===

func _on_slot_clicked(slot_index: int, mouse_event: InputEventMouseButton):
	"""Override avec debug pour hotbar"""
	
	print("🔥 [HOTBAR] Clic détecté sur slot %d !" % slot_index)
	
	# Appeler la méthode parent
	super._on_slot_clicked(slot_index, mouse_event)
