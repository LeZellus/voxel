# scripts/inventory/ui/InventorySlotUI.gd - VERSION DRAG & DROP CORRIGÉE
class_name InventorySlotUI
extends Control

# Signaux pour l'interaction
signal slot_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_right_clicked(slot_index: int, slot_ui: InventorySlotUI)
signal slot_hovered(slot_index: int, slot_ui: InventorySlotUI)
signal drag_started(slot_ui: InventorySlotUI, mouse_pos: Vector2)

@onready var background: NinePatchRect = $Background
@onready var item_icon: TextureRect = $ItemIcon  
@onready var quantity_label: Label = $QuantityLabel
@onready var button: Button = $Button

var slot_index: int = -1
var slot_data: Dictionary = {}
var is_selected: bool = false

# Variables pour le drag
var is_mouse_down: bool = false
var mouse_down_pos: Vector2
var drag_threshold: float = 5.0
var drag_started_flag: bool = false

func _ready():
	if button:
		# Configurer le button pour qu'il laisse passer les événements
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_button_mouse_entered)
	
	# Gérer les événements directement sur le Control principal
	gui_input.connect(_on_gui_input)
	clear_slot()

func _on_gui_input(event: InputEvent):
	"""Gestion directe des événements sur le Control"""
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_start_potential_drag(mouse_event.position)
			else:
				_end_potential_drag(mouse_event.position)
		
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			slot_right_clicked.emit(slot_index, self)
	
	elif event is InputEventMouseMotion and is_mouse_down and not drag_started_flag:
		_check_drag_threshold(event.position)

func _start_potential_drag(pos: Vector2):
	"""Démarre la détection de drag"""
	if is_empty():
		return
		
	is_mouse_down = true
	mouse_down_pos = pos
	drag_started_flag = false

func _end_potential_drag(pos: Vector2):
	"""Termine la détection de drag"""
	if is_mouse_down and not drag_started_flag:
		# C'était un simple clic, pas un drag
		slot_clicked.emit(slot_index, self)
	
	is_mouse_down = false
	drag_started_flag = false

func _check_drag_threshold(current_pos: Vector2):
	"""Vérifie si le seuil de drag est atteint"""
	if is_empty() or drag_started_flag:
		return
		
	var distance = mouse_down_pos.distance_to(current_pos)
	if distance > drag_threshold:
		drag_started_flag = true
		is_mouse_down = false
		
		# Émettre le signal avec la position globale de la souris
		drag_started.emit(self, get_global_mouse_position())

func _on_button_pressed():
	"""Fallback pour les clics directs sur le button"""
	if not drag_started_flag:
		slot_clicked.emit(slot_index, self)

func _on_button_mouse_entered():
	"""Gestion du hover"""
	slot_hovered.emit(slot_index, self)

# === GESTION DES DONNÉES DU SLOT ===

func update_slot(slot_info: Dictionary):
	"""Met à jour les données et l'affichage du slot"""
	slot_data = slot_info
	
	if slot_info.get("is_empty", true):
		clear_slot()
	else:
		_display_item(slot_info)

func _display_item(slot_info: Dictionary):
	"""Affiche un item dans le slot"""
	if item_icon:
		item_icon.texture = slot_info.get("icon")
		item_icon.visible = true
	
	if quantity_label:
		var qty = slot_info.get("quantity", 1)
		quantity_label.text = str(qty)
		quantity_label.visible = qty > 1

func clear_slot():
	"""Vide l'affichage du slot"""
	if item_icon:
		item_icon.texture = null
		item_icon.visible = false
		
	if quantity_label:
		quantity_label.text = ""
		quantity_label.visible = false
		
	slot_data = {"is_empty": true}

# === MÉTHODES PUBLIQUES ===

func get_slot_index() -> int:
	return slot_index

func set_slot_index(index: int):
	slot_index = index

func get_item_name() -> String:
	return slot_data.get("item_name", "")

func is_empty() -> bool:
	return slot_data.get("is_empty", true)

func set_selected(selected: bool):
	"""Marque le slot comme sélectionné"""
	is_selected = selected
	if background:
		background.modulate = Color.YELLOW if selected else Color.WHITE

func get_slot_data() -> Dictionary:
	return slot_data.duplicate()

func set_drag_preview_mode(enabled: bool):
	"""Active/désactive le mode aperçu pendant le drag"""
	modulate.a = 0.5 if enabled else 1.0

# === DEBUG ===

func _to_string() -> String:
	return "InventorySlotUI[%d]: %s" % [slot_index, "empty" if is_empty() else get_item_name()]
