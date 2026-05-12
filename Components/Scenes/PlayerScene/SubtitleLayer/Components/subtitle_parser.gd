extends Node
class_name SubtitleParser


static func load_subtitles(path: String) -> Array:
	if not FileAccess.file_exists(path):
		Debugger.error("Subtitles file not found: " + path)
		return []
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		Debugger.error("Can't open subtitles file: " + path)
		return []
	
	var result = JSON.parse_string(file.get_as_text())
	if result == null:
		Debugger.error("Invalid subtitles JSON")
		return []
	
	return result
