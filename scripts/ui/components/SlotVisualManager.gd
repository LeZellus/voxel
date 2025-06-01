# scripts/config/inventory/slot/SlotVisualManager.gd - VERSION CORRIGÉE
class_name SlotVisualManager
extends RefCounted

# === COMPOSANTS ===
var hover_display: SlotVisualDisplay
var selected_display: SlotVisualDisplay  
var error_display: SlotErrorDisplay
var parent_control: Control

# === ÉTATS ===
var current_state: SlotVisualState = SlotVisualState.NONE
var is_mouse_over: bool = false

enum SlotVisualState { NONE, HOVER, SELECTED, ERROR }

func _init(parent: Control):
	parent_control = parent

func create_overlays():
	"""Crée les composants d'affichage"""
	if not parent_control or not is_instance_valid(parent_control):
		print("❌ Parent control invalide pour SlotVisualManager")
		return
	
	# Attendre que le parent soit dans l'arbre
	if not parent_control.is_inside_tree():
		await parent_control.tree_entered
	
	# Créer les displays
	hover_display = SlotVisualDisplay.new(parent_control, SlotVisualConfig.HOVER)
	selected_display = SlotVisualDisplay.new(parent_control, SlotVisualConfig.SELECTED)
	error_display = SlotErrorDisplay.new(parent_control)
	
	# Connecter le signal de fin d'erreur
	if error_display and error_display.error_timer:
		error_display.error_timer.timeout.connect(_on_error_finished)

func _on_error_finished():
	"""Callback quand l'erreur se termine"""
	if current_state == SlotVisualState.ERROR:
		var target_state = SlotVisualState.HOVER if is_mouse_over else SlotVisualState.NONE
		_change_state(target_state)

# === API PUBLIQUE ===

func set_hover_state(hovered: bool):
	"""Gère l'état de survol"""
	is_mouse_over = hovered
	
	# Ne pas changer l'état si on est en erreur
	if current_state == SlotVisualState.ERROR:
		return
	
	if hovered and current_state == SlotVisualState.NONE:
		_change_state(SlotVisualState.HOVER)
	elif not hovered and current_state == SlotVisualState.HOVER:
		_change_state(SlotVisualState.NONE)

func set_selected_state(selected: bool):
	"""Gère l'état de sélection"""
	if selected:
		_change_state(SlotVisualState.SELECTED)
	else:
		# Retourner à l'état approprié selon la souris
		_change_state(SlotVisualState.HOVER if is_mouse_over else SlotVisualState.NONE)

func show_error_feedback():
	"""Affiche le feedback d'erreur"""
	_change_state(SlotVisualState.ERROR)

# === GESTION DES ÉTATS ===

func _change_state(new_state: SlotVisualState):
	"""Change l'état visuel"""
	if current_state == new_state:
		return
	
	_hide_current_state()
	current_state = new_state
	_show_current_state()

func _hide_current_state():
	"""Cache l'état actuel"""
	match current_state:
		SlotVisualState.HOVER: 
			if hover_display: hover_display.hide()
		SlotVisualState.SELECTED: 
			if selected_display: selected_display.hide()
		SlotVisualState.ERROR: 
			if error_display: error_display.hide()

func _show_current_state():
	"""Affiche le nouvel état"""
	match current_state:
		SlotVisualState.HOVER: 
			if hover_display: hover_display.show()
		SlotVisualState.SELECTED: 
			if selected_display: selected_display.show()
		SlotVisualState.ERROR: 
			if error_display: error_display.show()

func cleanup():
	"""Nettoie les ressources"""
	if hover_display: 
		hover_display.cleanup()
	if selected_display: 
		selected_display.cleanup()
	if error_display: 
		error_display.cleanup()

# === DEBUG ===

func debug_state():
	"""Affiche l'état pour debug"""
	print("🔍 SlotVisualManager État:")
	print("   - État actuel: %s" % SlotVisualState.keys()[current_state])
	print("   - Souris dessus: %s" % is_mouse_over)
	print("   - Hover display: %s" % (hover_display != null))
	print("   - Selected display: %s" % (selected_display != null))
	print("   - Error display: %s" % (error_display != null))
