class_name SlotVisualManager
extends RefCounted

# === COMPOSANTS ===
var hover_display: SlotVisualDisplay
var selected_display: SlotVisualDisplay  
var error_display: SlotErrorDisplay
var parent_control: Control

# === ÉTATS ===
var current_state: SlotVisualState = SlotVisualState.NONE

enum SlotVisualState { NONE, HOVER, SELECTED, ERROR }

func _init(parent: Control):
	parent_control = parent

func create_overlays():
	"""Crée les composants d'affichage"""
	await parent_control.get_tree().process_frame
	
	hover_display = SlotVisualDisplay.new(parent_control, SlotVisualConfig.HOVER)
	selected_display = SlotVisualDisplay.new(parent_control, SlotVisualConfig.SELECTED)
	error_display = SlotErrorDisplay.new(parent_control)

# === API PUBLIQUE ===
func set_hover_state(hovered: bool):
	if hover_display:
		hover_display.is_mouse_over = hovered
	
	if hovered and current_state == SlotVisualState.NONE:
		_change_state(SlotVisualState.HOVER)
	elif not hovered and current_state == SlotVisualState.HOVER:
		_change_state(SlotVisualState.NONE)

func set_selected_state(selected: bool):
	if selected:
		_change_state(SlotVisualState.SELECTED)
	else:
		_change_state(SlotVisualState.HOVER if hover_display.is_mouse_over else SlotVisualState.NONE)

func show_error_feedback():
	_change_state(SlotVisualState.ERROR)

func _change_state(new_state: SlotVisualState):
	if current_state == new_state:
		return
		
	_hide_current_state()
	current_state = new_state
	_show_current_state()

func _hide_current_state():
	match current_state:
		SlotVisualState.HOVER: hover_display.hide()
		SlotVisualState.SELECTED: selected_display.hide()
		SlotVisualState.ERROR: error_display.hide()

func _show_current_state():
	match current_state:
		SlotVisualState.HOVER: hover_display.show()
		SlotVisualState.SELECTED: selected_display.show()
		SlotVisualState.ERROR: error_display.show()

func cleanup():
	if hover_display: hover_display.cleanup()
	if selected_display: selected_display.cleanup()
	if error_display: error_display.cleanup()
