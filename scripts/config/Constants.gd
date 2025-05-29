# Constants.gd - Constantes du jeu (à créer dans scripts/manager/)
class_name Constants

# Inventaire
const INVENTORY_SIZE = 36
const GRID_COLUMNS = 9
const SLOT_SIZE = 64

# Audio
const FOOTSTEP_TOLERANCE = 0.05
const VOLUME_RANGE = Vector2(0.9, 1.1)
const PITCH_RANGE = Vector2(0.98, 1.02)

# Interaction
const INTERACTION_RANGE = 3.0
const SURFACE_DETECTION_DISTANCE = 2.0

# UI
const DRAG_THRESHOLD = 5.0
const CORNER_SIZE = 12
const BORDER_WIDTH = 2

# Surfaces (pour éviter les typos)
const SURFACES = {
	GRASS = "grass",
	STONE = "stone", 
	DIRT = "dirt",
	WOOD = "wood"
}
