class_name SurfaceDetector

static func detect_surface_under_player(player: CharacterBody3D) -> String:
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + Vector3.DOWN * Constants.SURFACE_DETECTION_DISTANCE
	)
	
	var result = space_state.intersect_ray(query)
	if not result:
		return Constants.SURFACES.WOOD  # Défaut
	
	var collider = result.get("collider")
	if not collider:
		return Constants.SURFACES.WOOD
	
	# Méthode custom en priorité
	if collider.has_method("get_surface_type"):
		return collider.get_surface_type()
	
	# Sinon chercher par groupe
	for surface_name in Constants.SURFACES.values():
		if collider.is_in_group(surface_name + "_surface"):
			return surface_name
	
	return Constants.SURFACES.WOOD
