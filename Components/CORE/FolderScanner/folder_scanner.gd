extends Node
class_name FolderScanner


func scan_folder(path: String) -> Array:
	Debugger.debug("imported path: " + path)
	var dir = DirAccess.open(path)
	if dir == null:
		Debugger.error("Failed to open: " + path)
		return []

	var result: Array = []
	var type_hint = null

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename == "." or filename == "..":
			filename = dir.get_next()
			continue

		if not dir.current_is_dir():
			match filename:
				"franchise_descriptions.json":
					type_hint = "catalog"
				"album_descriptions.json":
					type_hint = "franchise"
				"song_descriptions.json":
					type_hint = "album"
				"config.json":
					type_hint = "song"
		filename = dir.get_next()
	dir.list_dir_end()

	dir.list_dir_begin()
	filename = dir.get_next()
	while filename != "":
		if filename == "." or filename == "..":
			filename = dir.get_next()
			continue

		if dir.current_is_dir():
			result.append({
				"name": filename,
				"is_dir": true,
				"type_hint": type_hint
			})

		filename = dir.get_next()
	dir.list_dir_end()

	return result
