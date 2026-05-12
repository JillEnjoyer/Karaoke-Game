extends Node
class_name SceneRegistry

var scenes := {}


func build_scene_map():
	scenes = {}
	var dir = DirAccess.open("res://")
	if dir:
		_scan_directory(dir, "res://")
	return scenes


func _scan_directory_old(dir: DirAccess, path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = path.path_join(file_name)
		if dir.current_is_dir():
			var sub_dir = DirAccess.open(full_path)
			if sub_dir:
				_scan_directory(sub_dir, full_path)
		elif file_name.ends_with(".tscn"):
			var key = _path_to_key(full_path)
			scenes[key] = full_path

		file_name = dir.get_next()
	dir.list_dir_end()


func _scan_directory(dir: DirAccess, path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = path.path_join(file_name)
		
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				var sub_dir = DirAccess.open(full_path)
				if sub_dir:
					_scan_directory(sub_dir, full_path)
		else:
			var actual_path = full_path.replace(".remap", "").replace(".import", "")
			
			if actual_path.ends_with(".tscn") or actual_path.ends_with(".scn"):
				var key = _path_to_key(actual_path)
				if not scenes.has(key):
					scenes[key] = actual_path
					# Debugger.info("Registered scene: " + key + " -> " + actual_path)

		file_name = dir.get_next()
	dir.list_dir_end()


## Creates a standartized name based on "snake case"
## example: res://Components/MainMenu/MainMenu.tscn → MainMenu
func _path_to_key(path: String) -> String:
	return path.get_file().get_basename()#.to_snake_case()


func get_scene_path(scene_name: String) -> String:
	if scenes.has(scene_name):
		return scenes[scene_name]
	else:
		var suggestion = _find_closest_match(scene_name)
		push_warning("Scene \"%s\" not found. Did you mean \"%s\"?" % [scene_name, suggestion])
		return scenes.get(suggestion, "")


func load_scene(scene_name: String) -> PackedScene:
	var path = get_scene_path(scene_name)
	if path != "":
		return load(path)
	return null


func _find_closest_match(match_name: String) -> String:
	var closest = ""
	var max_match = 0
	for key in scenes.keys():
		var match = _common_prefix_len(key, match_name)
		if match > max_match:
			max_match = match
			closest = key
	return closest


func _common_prefix_len(a: String, b: String) -> int:
	var length = min(a.length(), b.length())
	var count = 0
	for i in length:
		if a[i] == b[i]:
			count += 1
		else:
			break
	return count


func get_all_scenes() -> Dictionary:
	return scenes.duplicate(true)
