extends Node

var data = {}

func _ready():
	load_json()

func add_name(name: String):
	data["Name"] = name
	print("Добавлено название:", name)

func add_mode(mode_type: String, mode_value: String):
	if not data.has("Modes"):
		data["Modes"] = {}
	
	data["Modes"][mode_type] = mode_value
	print("Добавлен режим:", mode_type, "->", mode_value)

func add_videotrack(id: int, filename: String):
	if not data.has("Videotracks"):
		data["Videotracks"] = {}
	
	data["Videotracks"][str(id)] = filename
	print("Добавлен видеотрек:", filename)

func add_audiotrack(id: int, track_type: String, version: String, language: String = "", file_type: String = ".mp3"):
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
	print("Добавлен аудиотрек:", track)

func add_character(name: String):
	if not data.has("Characters"):
		data["Characters"] = []
	
	if name not in data["Characters"]:
		data["Characters"].append(name)
		print("Добавлен персонаж:", name)

func save_json():
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://data.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("JSON сохранён!")
	else:
		print("Ошибка сохранения JSON!")

func load_json():
	var file = FileAccess.open("user://data.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parsed = JSON.parse_string(json_string)
		if parsed:
			data = parsed
			print("JSON загружен:", data)
		else:
			print("Ошибка парсинга JSON!")
	else:
		print("Файл не найден, создаём новый JSON.")
		data = {}
