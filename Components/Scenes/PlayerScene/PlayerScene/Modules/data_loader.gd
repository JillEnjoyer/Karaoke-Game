extends Node
class_name SongDataLoader

var video_dict := {}
var instrumental_dict := {}
var acapella_dict := {}
var subtitle_path := ""
var character_dict := []


func parse_config(config_path: String) -> void:
	var parser = ConfigParser.new()
	var parsed_data: Dictionary = parser.get_parsed_data(config_path)
	Debugger.debug(str(parsed_data))
	
	video_dict = parsed_data["video"]
	instrumental_dict = parsed_data["instrumental"]
	acapella_dict = parsed_data["acapella"]
	#subtitle_path = parsed_data["subtitle"]
	#character_dict = parsed_data["characters"]


func player_scene_partial_init(playlist_song: Dictionary = {}) -> Dictionary:
	var song_path = playlist_song["song_path"]
	var config_file = song_path.path_join("Configs").path_join(playlist_song["version"] + ".json")
	subtitle_path = song_path.path_join("Subtitles/[PREPARED]").path_join(playlist_song["version"] + ".json")

	if not FileAccess.file_exists(config_file):
		Debugger.error("Config file does not exist: " + str(config_file))
		return {}

	parse_config(config_file)
	
	return {
		"song_path": song_path,
		"video_dict": video_dict,
		"instrumental_dict": instrumental_dict,
		"acapella_dict": acapella_dict,
		"subtitle_path": subtitle_path,
		"character_dict": character_dict
	}


func highlight_partial_init(song_path: String = "", input_highlight_data: Array = [], is_random: bool = false) -> Dictionary:
	var highlight_config

	var length = input_highlight_data.size()
	if length > 0:
		if is_random:
			highlight_config = input_highlight_data.pick_random()
		else:
			highlight_config = input_highlight_data[0]
	else:
		Debugger.warning("No highlights found for: " + song_path)
		return {}
	
	var version = highlight_config.get("version", "")
	var highlight_start = highlight_config.get("logical_start", 0.0)
	var highlight_end = highlight_config.get("logical_end", 1.0)
	var highlight_repeat = highlight_config.get("repeat", false)

	var highlight_type: String = highlight_config.get("highlight_type", "standard")
	var highlight_extras: Array = highlight_config.get("highlight_extras", [])
	
	var config_file = song_path.path_join("Configs").path_join(version + ".json")
	if not FileAccess.file_exists(config_file):
		Debugger.error("Config file does not exist: " + str(config_file))
		return {}
	
	parse_config(config_file)

	return {
		"song_path": song_path,
		"video_dict": video_dict,
		"instrumental_dict": instrumental_dict,
		"acapella_dict": acapella_dict,
		"version": version,
		"highlight_start": highlight_start,
		"highlight_end": highlight_end,
		"highlight_repeat": highlight_repeat,
		"highlight_type": highlight_type,
		"highlight_extras": highlight_extras,
		"config_file": config_file
	}


func debug_print() -> void:
	Debugger.debug("Video dict: " + str(video_dict))
	Debugger.debug("Instrumental dict: " + str(instrumental_dict))
	Debugger.debug("Acapella dict: " + str(acapella_dict))
	Debugger.debug("Subtitle path: " + str(subtitle_path))
	Debugger.debug("Character dict: " + str(character_dict))
