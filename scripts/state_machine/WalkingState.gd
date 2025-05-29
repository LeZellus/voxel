extends State
class_name WalkingState

@onready var dust_particles: GPUParticles3D = %DustParticles

var last_speed: float = 0.0
var last_surface: String = ""

func enter():
	if player.animation_player:
		player.animation_player.play("Run")
		player.animation_player.speed_scale = 4.0
	
	dust_particles.emitting = true
	
	# Configuration des sons de pas
	AudioManager.set_footstep_positions([0.3, 1.0])  # Ajustez selon vos besoins
	AudioManager.set_footstep_tolerance(0.05)
	AudioManager.set_footstep_volume(0.1)
	AudioManager.start_footsteps(player.walk_speed, "wood", player.animation_player)
	
	last_speed = player.walk_speed
	last_surface = "wood"

func physics_update(delta):
	player.apply_gravity(delta)
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.length() == 0:
		state_machine.change_state("idle")
		return
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		AudioManager.play_player_sound("jump", "actions")
		state_machine.change_state("jumping")
		return
	
	var speed = player.run_speed if Input.is_action_pressed("run") else player.walk_speed
	var current_surface = get_current_surface()
	
	# Mettre à jour si changement significatif
	if abs(speed - last_speed) > 0.5 or current_surface != last_surface:
		AudioManager.start_footsteps(speed, current_surface, player.animation_player)
		last_speed = speed
		last_surface = current_surface
	
	var direction = player.get_movement_direction_from_camera()
	player.apply_movement(direction, speed, delta)
	player.move_and_slide()
	
	# Mise à jour de la synchronisation
	AudioManager.update_footsteps()

func exit():
	if player.animation_player:
		player.animation_player.stop()
	
	dust_particles.emitting = false
	AudioManager.stop_footsteps()
	
	last_speed = 0.0
	last_surface = ""

func get_current_surface() -> String:
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + Vector3.DOWN * 2.0
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.get("collider")
		if collider and collider.has_method("get_surface_type"):
			return collider.get_surface_type()
		
		if collider and collider.is_in_group("grass_surface"):
			return "grass"
		elif collider and collider.is_in_group("stone_surface"):
			return "stone"
		elif collider and collider.is_in_group("dirt_surface"):
			return "dirt"
		elif collider and collider.is_in_group("wood_surface"):
			return "wood"
	
	return "wood"
