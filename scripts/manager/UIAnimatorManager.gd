# UIAnimator.gd - Gestionnaire d'animations réutilisable
class_name UIAnimator
extends RefCounted

static func slide_inventory_from_bottom(panel: Panel, estimated_height: float, duration: float = 0.4) -> Tween:
	var viewport_size = panel.get_viewport().size
	var screen_height = viewport_size.y
	var final_y = screen_height - estimated_height - 4
	
	panel.position.y = screen_height
	
	var tween = panel.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position:y", final_y, duration)
	
	return tween

static func slide_inventory_to_bottom(panel: Panel, duration: float = 0.3) -> Tween:
	var viewport_size = panel.get_viewport().size
	var screen_height = viewport_size.y
	
	var tween = panel.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position:y", screen_height, duration)
	
	return tween

static func slide_from_bottom(control: Control, target_pos: Vector2, duration: float = 0.4) -> Tween:
	var viewport_size = control.get_viewport().size
	var start_pos = Vector2(target_pos.x, viewport_size.y)
	
	control.position = start_pos
	control.visible = true
	
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "position", target_pos, duration)
	
	return tween

static func slide_to_bottom(control: Control, duration: float = 0.3) -> Tween:
	var viewport_size = control.get_viewport().size
	var end_pos = Vector2(control.position.x, viewport_size.y)
	
	var tween = control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "position", end_pos, duration)
	
	tween.finished.connect(func(): control.visible = false)
	
	return tween

static func fade_in(control: Control, duration: float = 0.2) -> Tween:
	control.modulate.a = 0.0
	control.visible = true
	
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)
	
	return tween

static func fade_out(control: Control, duration: float = 0.2) -> Tween:
	var tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 0.0, duration)
	
	tween.finished.connect(func(): control.visible = false)
	
	return tween
