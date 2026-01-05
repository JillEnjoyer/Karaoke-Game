class_name ConfigParser

var json = JSON.new()

var returnable_data: Dictionary = {
		"video": {},
		"instrumental": {},
		"acapella": {},
		"character_list": []
	}

var data: Dictionary = {}

## PARSER ##
func get_parsed_data(config_path: String) -> Dictionary:
	_load_and_parse(config_path)
	return returnable_data


func _load_and_parse(config_path: String) -> void:
	if not FileAccess.file_exists(config_path):
		Debugger.error("File missing: " + config_path)
		return

	# get_file_as_string is file.open() and file.close() analogue 
	var json_text = FileAccess.get_file_as_string(config_path)
	var parsed_data = JSON.parse_string(json_text)

	if not parsed_data is Dictionary:
		Debugger.error("Invalid JSON format")
		return

	# Getting data in correct format
	returnable_data = parsed_data.get("files", {})
	returnable_data["characters"] = parsed_data.get("characters", [])

	Debugger.debug("Data flattened and loaded: " + str(returnable_data.keys()))


## UNPARSER ##
## TODO: Refactor with this way:
"""
func save_config(save_path: String) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
"""
func save_config(data: Dictionary, save_path: String) -> void:
	var json_dict := {
		"files": {
			"video": {},
			"instrumental": {},
			"acapella": {}
		},
		"characters": []
	}

	for video_name in data["video"]:
		var entry = data["video"][video_name]
		json_dict["files"]["video"][video_name] = {
			"path": entry.get("path", ""),
			"jumpers": entry.get("jumpers", [])
		}

	for inst_name in data["instrumental"]:
		var entry = data["instrumental"][inst_name]
		json_dict["files"]["instrumental"][inst_name] = {
			"path": entry.get("path", ""),
			"jumpers": entry.get("jumpers", [])
		}

	for character in data["acapella"]:
		var entry = data["acapella"][character]
		json_dict["files"]["acapella"][character] = {
			"path": entry.get("path", ""),
			"jumpers": entry.get("jumpers", [])
		}

	json_dict["characters"] = data.get("character_list", [])

	# save JSON
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		Debugger.error("Cannot open file for writing: " + save_path)
		return

	var json_text = json.print(json_dict, "\t")
	file.store_string(json_text)
	file.close()
	Debugger.debug("Config saved successfully: " + save_path)
