# Constants.gd - Configuration centralisée optimisée
class_name Constants
extends RefCounted

# === INVENTAIRE ===
const INVENTORY_SIZE = 45
const GRID_COLUMNS = 9
const GRID_ROWS = 5.0
const SLOT_SIZE = 64.0

# Valeurs calculées automatiquement
const HOTBAR_SIZE = GRID_COLUMNS  # 9 slots = 1 ligne
const MAIN_INVENTORY_SLOTS = GRID_COLUMNS * GRID_ROWS  # 45 slots

# === AUDIO ===
const FOOTSTEP_TOLERANCE = 0.05
const VOLUME_RANGE = Vector2(0.9, 1.1)
const PITCH_RANGE = Vector2(0.98, 1.02)

# === INTERACTION ===
const INTERACTION_RANGE = 3.0
const SURFACE_DETECTION_DISTANCE = 2.0

# === CAMERA ===
const CAMERA_COLLISION_MARGIN = 0.5   # Marge SpringArm
const CAMERA_DEFAULT_ROTATION = -0.3  # Rotation par défaut
const CAMERA_MOUSE_SENSIVITY = 0.002  # Sensibilité souris caméra
const CAMERA_MIN_VERTICAL_ANGLE = -PI/2  # Angle de caméra joueur minimum
const CAMERA_MAX_VERTICAL_ANGLE = PI/4 # Angle de caméra joueur maximum
const CAMERA_MAX_SPRING_LENGTH = 8.0
const CAMERA_MAX_ZOOM_MIN = 3.0 # Angle de caméra joueur maximum
const CAMERA_MAX_ZOOM_MAX = 15.0 # Angle de caméra joueur maximum
const CAMERA_MAX_ZOOM_STEP = 1.0 # Angle de caméra joueur maximum

# === UI ===
const DRAG_THRESHOLD = 5.0
const CORNER_SIZE = 12
const BORDER_WIDTH = 2

# Tailles UI calculées
const SLOT_PIXEL_SIZE = Vector2(SLOT_SIZE, SLOT_SIZE)
const HOTBAR_WIDTH = GRID_COLUMNS * SLOT_SIZE  # 576px
const INVENTORY_WIDTH = GRID_COLUMNS * SLOT_SIZE  # 576px
const INVENTORY_HEIGHT = GRID_ROWS * SLOT_SIZE  # 320px

# === SURFACES ===
const SURFACES = {
	GRASS = "grass",
	STONE = "stone", 
	DIRT = "dirt",
	WOOD = "wood"
}

# === ANIMATIONS UI (fusion de UIConstants.gd) ===
const UI_POSITIONS = {
	"HOTBAR_TOP_MARGIN": 4.0,
	"INVENTORY_CENTER_OFFSET": Vector2.ZERO
}

const UI_ANIMATIONS = {
	"SLIDE_DURATION": 0.4,
	"FADE_DURATION": 0.3
}

# === GETTERS PRATIQUES ===
static func get_hotbar_size() -> int:
	return HOTBAR_SIZE

static func get_main_inventory_size() -> int:
	return MAIN_INVENTORY_SLOTS

static func get_slot_size() -> Vector2:
	return SLOT_PIXEL_SIZE

static func get_ui_slide_duration() -> float:
	return UI_ANIMATIONS.SLIDE_DURATION

static func get_ui_fade_duration() -> float:
	return UI_ANIMATIONS.FADE_DURATION
