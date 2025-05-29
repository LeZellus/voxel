class_name AudioUtils

# Chargement récursif des sons
static func load_sounds_from_directory(path: String) -> Dictionary:
	var sounds = {}
	var dir = DirAccess.open(path)
	if not dir:
		return sounds
	
	_load_recursive(dir, path, sounds)
	return sounds

static func _load_recursive(dir: DirAccess, path: String, sounds: Dictionary):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			var subdir = DirAccess.open(full_path)
			if subdir:
				_load_recursive(subdir, full_path + "/", sounds)
		elif file_name.get_extension() in ["ogg", "wav", "mp3"]:
			sounds[file_name.get_basename()] = load(full_path)
		
		file_name = dir.get_next()

# Sélection de sons intelligente
static func select_footstep_sound(sounds: Dictionary, surface: String, last_sound: String) -> String:
	var filtered_sounds = sounds.keys().filter(func(name): 
		return name.contains("step") and name.contains(surface)
	)
	
	if filtered_sounds.is_empty():
		filtered_sounds = sounds.keys().filter(func(name): return name.contains("step"))
	
	if filtered_sounds.is_empty():
		return ""
	
	# Éviter répétition
	if filtered_sounds.size() > 1:
		filtered_sounds.erase(last_sound)
		if filtered_sounds.is_empty():
			filtered_sounds = sounds.keys().filter(func(name): return name.contains("step"))
	
	return filtered_sounds[randi() % filtered_sounds.size()]
