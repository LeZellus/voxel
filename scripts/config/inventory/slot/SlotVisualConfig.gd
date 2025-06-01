# scripts/config/SlotVisualConfig.gd
class_name SlotVisualConfig
extends RefCounted

# === COULEURS ===
const HOVER_COLOR = Color(1, 1, 1, 0.15)        # Blanc semi-transparent
const SELECTED_COLOR = Color(0.2, 0.8, 1.0, 0.4) # Bleu semi-transparent
const SELECTED_BORDER_COLOR = Color(0.2, 0.8, 1.0, 0.8) # Bleu bordure

# === STYLES ALTERNATIFS ===
const HOVER_COLOR_WARM = Color(1, 0.8, 0.3, 0.2)      # Orange chaud
const SELECTED_COLOR_GREEN = Color(0.3, 0.8, 0.3, 0.4) # Vert
const SELECTED_COLOR_PURPLE = Color(0.8, 0.3, 0.8, 0.4) # Violet

# === DIMENSIONS ===
const BORDER_THICKNESS = 2
const OVERLAY_MARGIN = 0  # Marge intérieure pour les overlays

# === ANIMATIONS (pour plus tard) ===
const HOVER_FADE_DURATION = 0.1
const SELECT_FADE_DURATION = 0.15

# === GETTERS ===
static func get_hover_color() -> Color:
	return HOVER_COLOR

static func get_selected_color() -> Color:
	return SELECTED_COLOR

static func get_border_color() -> Color:
	return SELECTED_BORDER_COLOR

static func get_border_thickness() -> int:
	return BORDER_THICKNESS

# === VARIANTES DE STYLE ===
static func get_style_variant(variant: String) -> Dictionary:
	match variant:
		"warm":
			return {
				"hover": HOVER_COLOR_WARM,
				"selected": Color(1, 0.6, 0.1, 0.4),
				"border": Color(1, 0.6, 0.1, 0.8)
			}
		"nature":
			return {
				"hover": Color(0.6, 1, 0.6, 0.15),
				"selected": SELECTED_COLOR_GREEN,
				"border": Color(0.3, 0.8, 0.3, 0.8)
			}
		"magic":
			return {
				"hover": Color(1, 0.6, 1, 0.15),
				"selected": SELECTED_COLOR_PURPLE,
				"border": Color(0.8, 0.3, 0.8, 0.8)
			}
		_:
			return {
				"hover": HOVER_COLOR,
				"selected": SELECTED_COLOR,
				"border": SELECTED_BORDER_COLOR
			}
