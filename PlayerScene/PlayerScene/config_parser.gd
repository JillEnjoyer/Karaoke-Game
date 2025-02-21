extends Node

class_name ConfigParser

var video_link: String = ""
var instrumental_link: String = ""
var acapella_list: Dictionary = {}
var character_list: Dictionary = {}
var subtitles_list: Array = []

func parse_config(config_path: String) -> void:
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + config_path)
		return

	var current_acapella_group = ""

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue

		if line.begins_with("[Video]"):
			video_link = line.replace("[Video]", "[Video]").strip_edges()
		elif line.begins_with("[Instrumental]"):
			instrumental_link = line.replace("[Instrumental]", "[Instrumental]").strip_edges()
		elif line.begins_with("[Acapella]"):
			current_acapella_group = line.replace("[Acapella]", "").strip_edges()
			acapella_list[current_acapella_group] = []
		elif line.begins_with("[Character]") and current_acapella_group != "":
			var character_name = line.replace("[Character]", "").strip_edges()
			acapella_list[current_acapella_group].append(character_name)
			character_list[character_name] = current_acapella_group
		elif line.begins_with("[Subtitles]"):
			var subtitle_info = line.replace("[Subtitles]", "").strip_edges()
			subtitles_list.append(subtitle_info)

	file.close()

func get_parsed_data(config_path: String) -> Dictionary:
	
	parse_config(config_path)
	
	Debugger.debug("config_parser.gd", "get_parsed_data()", "video_link: " + video_link)
	Debugger.debug("config_parser.gd", "get_parsed_data()", "instrumental_link: " + instrumental_link)
	Debugger.debug("config_parser.gd", "get_parsed_data()", "acapella_list: " + str(acapella_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "character_list: " + str(character_list))
	Debugger.debug("config_parser.gd", "get_parsed_data()", "subtitles_list: " + str(subtitles_list))
	
	return {
		"video_link": video_link,
		"instrumental_link": instrumental_link,
		"acapella_list": acapella_list,
		"character_list": character_list,
		"subtitles_list": subtitles_list
	}
