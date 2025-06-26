extends Node

var data = {}

func _ready():
	load_json()

func add_name(name: String) -> void:
	data["Name"] = name

func add_mode(mode_type: String, mode_value: String) -> void:
	if not data.has("Modes"):
		data["Modes"] = {}
	
	data["Modes"][mode_type] = mode_value
	Debugger.info("Added mode: " + mode_type + "->" + mode_value)

func add_videotrack(id: int, filename: String) -> void:
	if not data.has("Videotracks"):
		data["Videotracks"] = {}
	
	data["Videotracks"][str(id)] = filename
	Debugger.info("Added videotrack:", filename)

func add_audiotrack(id: int, track_type: String, version: String, language: String = "", file_type: String = ".mp3") -> void:
	if not data.has("Audiotracks"):
		data["Audiotracks"] = {}
	
	if not data["Audiotracks"].has(track_type):
		data["Audiotracks"][track_type] = []
	
	var track = {
		"id": id,
		"version": version,
		"language": language if language != "" else null,
		"file type": file_type,
		"params": {
			"offset_start": 0,
			"offset_end": 0,
			"gain": 0,
			"pitch": 0,
			"speed": 1.0
		}
	}
	data["Audiotracks"][track_type].append(track)
	Debugger.info("Added audiotrack:", track)

func add_character(name: String) -> void:
	if not data.has("Characters"):
		data["Characters"] = []
	
	if name not in data["Characters"]:
		data["Characters"].append(name)
		Debugger.info("Character added:", name)

func save_json() -> void:
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://data.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		Debugger.info("JSON is saved!")
	else:
		Debugger.error("Error with JSON saving")

func load_json() -> void:
	var file = FileAccess.open("user://data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(json_string)
		if parsed:
			data = parsed
			Debugger.debug("JSON loaded:" + data)
		else:
			Debugger.error("Error with JSON parsing")
	else:
		Debugger.info("File is not found, creating nef JSON")
		data = {}
