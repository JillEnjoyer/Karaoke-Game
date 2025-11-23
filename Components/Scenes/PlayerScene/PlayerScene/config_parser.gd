extends Node
class_name ConfigParser

var character_list: Array = []

var video_dict: Dictionary = {}
var instrumental_dict: Dictionary = {}
var acapella_dict: Dictionary = {}


func parse_json_config(config_path: String) -> void:
	if not FileAccess.file_exists(config_path):
		Debugger.error("File does not exist: " + config_path)
		return

	var config_file = FileAccess.open(config_path, FileAccess.READ)
	if config_file == null:
		Debugger.error("Failed to open file: " + config_path + ", error: " + str(FileAccess.get_open_error()))
		return

	var json_text = config_file.get_as_text()
	config_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		Debugger.error("Failed to open file: " + config_path + ", error: " + str(FileAccess.get_open_error()))
		return

	var parsed_data = json.get_data()
	if not parsed_data is Dictionary:
		Debugger.error("Invalid JSON format - expected Dictionary")
		return

	_clear_all_data()

	_parse_video_tracks(parsed_data.get("Videotracks", {}))

	var audio_tracks = parsed_data.get("Audiotracks", {})
	_parse_instrumental_tracks(audio_tracks.get("Instrumental", {}))
	_parse_acapella_tracks(audio_tracks.get("Acapella", {}))

	character_list = parsed_data.get("Characters", [])
	Debugger.debug("Data loaded successfully")


func _clear_all_data() -> void:
	character_list.clear()
	
	video_dict.clear()
	instrumental_dict.clear()
	acapella_dict.clear()


func _parse_video_tracks(video_tracks: Dictionary) -> void:
	for version_name in video_tracks:
		var track_data = video_tracks[version_name]
		if not track_data is Dictionary:
			Debugger.error("Invalid video track data for version: " + version_name)
			continue
			
		var video_entry = {
			"path": track_data.get("path", ""),
			"params": track_data.get("params", {})
		}
		
		if video_entry["path"]:
			video_dict[version_name] = video_entry
		else:
			Debugger.error("Video track '%s' has no path specified" % version_name)


func _parse_instrumental_tracks(instrumental_tracks: Dictionary) -> void:
	instrumental_dict.clear()
	
	for version in instrumental_tracks:
		var track_data = instrumental_tracks[version]
		if not track_data is Dictionary:
			Debugger.error("Invalid instrumental track data for version: " + version)
			continue
			
		var files = track_data.get("files", {})
		if not files is Dictionary:
			Debugger.error("Invalid files format in instrumental track: " + version)
			continue
		
		if not instrumental_dict.has(version):
			instrumental_dict[version] = {}
			
		for audio_key in files:
			var audio_data = files[audio_key]
			if not audio_data is Dictionary:
				Debugger.warn("Invalid audio data in %s/%s" % [version, audio_key])
				continue
				
			var entry = {
				"path": audio_data.get("path", ""),
				"params": audio_data.get("params", {})
			}
			
			if entry["path"]:
				instrumental_dict[version][audio_key] = entry
			else:
				Debugger.error("Instrumental track '%s/%s' has no path specified" % [version, audio_key])


func _parse_acapella_tracks(acapella_tracks: Dictionary) -> void:
	acapella_dict.clear()
	
	for version in acapella_tracks:
		var track_data = acapella_tracks[version]
		if not track_data is Dictionary:
			Debugger.error("Invalid acapella track data for version: " + version)
			continue
			
		var files = track_data.get("files", {})
		if not files is Dictionary:
			Debugger.error("Invalid files format in acapella track: " + version)
			continue
		
		if not acapella_dict.has(version):
			acapella_dict[version] = {}
			
		for audio_key in files:
			var audio_data = files[audio_key]
			if not audio_data is Dictionary:
				Debugger.warn("Invalid audio data in %s/%s" % [version, audio_key])
				continue
				
			var entry = {
				"path": audio_data.get("path", ""),
				"params": audio_data.get("params", {})
			}
			
			if entry["path"]:
				acapella_dict[version][audio_key] = entry
			else:
				Debugger.error("Acapella track '%s/%s' has no path specified" % [version, audio_key])


func get_parsed_data(config_path: String, desired_video: String = "", desired_instrumental: String = "", desired_acapella: String = "") -> Dictionary:
	parse_json_config(config_path)
	
	Debugger.debug("Input parameters:" + str({
		"desired_video": desired_video,
		"desired_instrumental": desired_instrumental,
		"desired_acapella": desired_acapella
	}))
	
	var filtered_video = {}
	if desired_video:
		if video_dict.has(desired_video):
			filtered_video[desired_video] = video_dict[desired_video]
	else:
		filtered_video = video_dict.duplicate()
	
	var filtered_instrumental = {}
	if desired_instrumental:
		if instrumental_dict.has(desired_instrumental):
			filtered_instrumental[desired_instrumental] = instrumental_dict[desired_instrumental]
	else:
		filtered_instrumental = instrumental_dict.duplicate()
	
	var filtered_acapella = {}
	if desired_acapella:
		if acapella_dict.has(desired_acapella):
			filtered_acapella[desired_acapella] = acapella_dict[desired_acapella]
	else:
		filtered_acapella = acapella_dict.duplicate()
	
	Debugger.debug("Filtered results:" + str({
		"video": filtered_video,
		"instrumental": filtered_instrumental,
		"acapella": filtered_acapella
	}))
	
	return {
		"video_dict": filtered_video,
		"instrumental_dict": filtered_instrumental,
		"acapella_dict": filtered_acapella,
		"character_list": character_list.duplicate()
	}
