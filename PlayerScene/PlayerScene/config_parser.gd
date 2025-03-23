extends Node

class_name ConfigParser

var video_list: Array = []
var instrumental_list: Array = []
var acapella_list: Array = []
var character_list: Array = []
var subtitles_list: Array = []

func parse_json_config(config_path: String) -> void:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + config_path)
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return

	var parsed_data = json.get_data()
	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Invalid JSON format")
		return

	video_list.clear()
	if parsed_data.has("Videotracks") and parsed_data["Videotracks"] is Dictionary:
		for key in parsed_data["Videotracks"].keys():
			var video_entry = parsed_data["Videotracks"][key]
			if video_entry is Dictionary:
				video_list.append({
					"id": key,
					"version": video_entry.get("version", "Unknown"),
					"type": video_entry.get("type", ".mp4"),
					"params": video_entry.get("params", {})
				})

	instrumental_list.clear()
	if parsed_data.has("Audiotracks") and parsed_data["Audiotracks"] is Dictionary:
		if parsed_data["Audiotracks"].has("Instrumental"):
			for track in parsed_data["Audiotracks"]["Instrumental"]:
				instrumental_list.append({
					"id": track.get("id", -1),
					"version": track.get("version", "Unknown"),
					"params": track.get("params", {})
				})

	acapella_list.clear()
	if parsed_data["Audiotracks"].has("Acapella"):
		for track in parsed_data["Audiotracks"]["Acapella"]:
			acapella_list.append({
				"id": track.get("id", -1),
				"version": track.get("version", "Unknown"),
				"language": track.get("language", "Unknown"),
				"params": track.get("params", {})
			})

	character_list = parsed_data.get("Characters", [])

	Debugger.debug("config_parser.gd", "parse_json_config()", "video_list: " + str(video_list))


func get_parsed_data(config_path: String) -> Dictionary:
	parse_json_config(config_path)

	Debugger.debug("config_parser.gd", "get_parsed_data()", "video_list: " + str(video_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "instrumental_list: " + str(instrumental_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "acapella_list: " + str(acapella_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "character_list: " + str(character_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "subtitles_list: " + str(subtitles_list))

	return {
		"video_list": video_list,
		"instrumental_list": instrumental_list,
		"acapella_list": acapella_list,
		"character_list": character_list,
		"subtitles_list": subtitles_list
	}
