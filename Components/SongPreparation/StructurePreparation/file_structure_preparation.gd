extends Node

class_name FileStructurePreparation
const DEFAULTS = "res://Defaults"
const TYPES := {
		"franchise": "album_descriptions.json", 
		"album": "about.json",
		"song": "config.json"
	}
const PLACEHOLDER_IMAGE: String = "res://icon.svg"

func ensure_folders_exist(path: String) -> void:
	if path.is_empty():
		Debugger.error("Path variable is empty")
		return
	
	if not DirAccess.dir_exists_absolute(path):
		var err = DirAccess.make_dir_recursive_absolute(path)
		if err != OK:
			Debugger.error("Failed to create folder: " + path)


func copy_default_json(path: String, type: String) -> void:
	var src_path: String = DEFAULTS + "/" +TYPES[type]
	var dst_path := ""
	
	match type:
		"franchise":
			dst_path = path.path_join("/album_descriptions.json")
		"album":
			dst_path = path.path_join("/about.json")
		"song":
			dst_path = path.path_join("/config.json")
		_:
			Debugger.error("Unknown type: " + type)
			return

	var content := ""
	var src_file := FileAccess.open(src_path, FileAccess.READ)
	if src_file:
		content = src_file.get_as_text()
		src_file.close()
	else:
		Debugger.error("Cannot read default: " + src_path)
		return

	var dst_file := FileAccess.open(dst_path, FileAccess.WRITE)
	if dst_file:
		dst_file.store_string(content)
		dst_file.close()
	else:
		Debugger.error("Cannot write to: " + dst_path)


func add_chosen_images(path: String, images: Dictionary) -> void:
	for key in images.keys():
		if key == "Name":
			continue
		var image_path: String = images[key]
		if image_path.is_empty():
			image_path = PLACEHOLDER_IMAGE

		var extension = image_path.get_extension()
		var dest_file = path + "/" + key + "." + extension

		if not FileAccess.file_exists(image_path):
			Debugger.error("File is not exist: ", image_path)
			continue

		var file = FileAccess.open(image_path, FileAccess.READ)
		if file:
			var data = file.get_buffer(file.get_length())
			file.close()

			var out = FileAccess.open(dest_file, FileAccess.WRITE)
			if out:
				out.store_buffer(data)
				out.close()
			else:
				Debugger.error("Failed to create file in destination folder: ", dest_file)
		else:
			Debugger.error("Failed to open source file: ", image_path)
