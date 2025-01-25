extends Node

@onready var localization_json = {}

func _ready() -> void:
	load_localization("ENG")


func load_localization(current_loc_str: String) -> void:
	var path = "res://Localization/loc_" + current_loc_str + ".json"
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file = null

		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK:
			localization_json = json.data
		else:
			print("Parsing error JSON:", json.get_error_message(), " on line ", json.get_error_line())
	else:
		print("Localization key is not found:", path)


func get_localized_line(loc_key: String) -> String:
	if loc_key in localization_json:
		return localization_json[loc_key]
	else:
		print("Localization key is not found:", loc_key)
		return loc_key
