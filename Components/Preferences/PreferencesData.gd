extends Node

const config_path = "res://SaveData/Config.cfg"
const user_data_path = "res://SaveData/UserData.cfg"
const ext_path = {
	"ffmpeg": "res://Extensions/ffmpeg.exe",
	"7z": "res://Extensions/7z.exe",
	"qrGenerator": "res://Extensions/qrGenerator.exe",
	"Vosk_Handler": "res://Extensions/Vosk_Handler_V1.1.exe",
}

var BaseSettingsList = {
	"resolution": Vector2(1280, 720),
	"language": "ENG",
	"window_mode": "Window",
	"framerate": 75,
	"v-sync": true,
	"overall_volume": 100,
	"mic_status": "Currently Unsupported",
	"countdown_time": 4,
	"debugger_enabled": true,
	"log_file_path": "",
	"catalog_path": "W:/Projects/Godot/Karaoke/Catalog"
}
var BaseUserData = {
	"main_menu_tutorial_passed": false,
	"song_preparation_tutorial_passed": false,
	"catalog_tutorial_passed": false,
	"player_scene_tutorial_passed": false,
	"song_setup_tutorial_passed": false,
	"settings_tutorial_passed": false
}

var SettingsList = BaseSettingsList.duplicate()
var UserData = BaseUserData.duplicate()


func _ready() -> void:
	# Config
	if not FileAccess.file_exists(config_path):
		Debugger.error("Config file not found. Creating new with base settings...")
		create_and_save_config(BaseSettingsList)
	else:
		Debugger.info("Loading settings...")
		var loaded_settings = load_config()
		if loaded_settings["result"] == null:
			Debugger.error("Failed to load config. Rewriting with base settings.")
			create_and_save_config(BaseSettingsList)
		else:
			update_settings_from_dictionary(loaded_settings["result"])

	# UserData
	if not FileAccess.file_exists(user_data_path):
		Debugger.error("UserData file not found. Creating new with base user data...")
		save_user_data()
	else:
		Debugger.info("Loading user data...")
		var loaded_user_data = load_user_data()
		if loaded_user_data["result"] == null:
			Debugger.error("Failed to load UserData. Rewriting with base user data.")
			save_user_data()
		else:
			for key in loaded_user_data["result"].keys():
				setUserData(key, loaded_user_data["result"][key])

# === CONFIG (SettingsList) ===

func create_and_save_config(settings: Dictionary) -> void:
	ensure_directories_exist(config_path)
	var settings_to_save = convert_resolution_for_save(settings)
	SettingsList = settings_to_save.duplicate()
	save_config()


func save_config() -> void:
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(SettingsList, "\t"))
		file.close()
		Debugger.info("Settings saved successfully: " + str(config_path))
	else:
		Debugger.error("Failed to open file for writing: " + str(config_path))


func load_config() -> Dictionary:
	var data = { "error": null, "result": null }

	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parsed_data = JSON.parse_string(content)
			if parsed_data == null:
				data["error"] = "JSON parsing failed"
				Debugger.error(data["error"])
			else:
				data["result"] = parsed_data
				if "resolution" in data["result"]:
					var res = data["result"]["resolution"]
					if res is Array and res.size() == 2:
						data["result"]["resolution"] = Vector2(res[0], res[1])
		else:
			data["error"] = "Cannot open config file"
	else:
		data["error"] = "Config file not found"

	return data


func update_settings_from_dictionary(new_settings: Dictionary) -> void:
	for key in new_settings.keys():
		setData(key, new_settings[key])


func convert_resolution_for_save(settings: Dictionary) -> Dictionary:
	var copy = settings.duplicate()
	if copy.has("resolution"):
		copy["resolution"] = [copy["resolution"].x, copy["resolution"].y]
	return copy


# === USERDATA ===

func save_user_data() -> void:
	var file = FileAccess.open(user_data_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(UserData, "\t"))
		file.close()
		Debugger.info("UserData saved successfully: " + str(user_data_path))
	else:
		Debugger.error("Failed to open UserData file for writing")


func load_user_data() -> Dictionary:
	var data = { "error": null, "result": null }

	if FileAccess.file_exists(user_data_path):
		var file = FileAccess.open(user_data_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var parsed_data = JSON.parse_string(content)
			if parsed_data == null:
				data["error"] = "JSON parsing failed for UserData"
				Debugger.error(data["error"])
			else:
				data["result"] = parsed_data
		else:
			data["error"] = "Cannot open UserData file"
	else:
		data["error"] = "UserData file not found"

	return data


# === Утилиты и доступ ===

func ensure_directories_exist(file_path: String) -> void:
	var dir_path = file_path.get_base_dir()
	var dir = DirAccess.open(dir_path)
	if dir == null:
		dir = DirAccess.open("res://")
		var err = dir.make_dir_recursive(dir_path)
		if err == OK:
			Debugger.info("Directory created: " + str(dir_path))
		else:
			Debugger.error("Failed to create directory: " + str(err))


func getData(setting: String):
	return SettingsList.get(setting, null)


func setData(setting: String, value) -> void:
	if SettingsList.has(setting):
		SettingsList[setting] = value


func getUserData(key: String):
	return UserData.get(key, null)


func setUserData(key: String, value) -> void:
	if UserData.has(key):
		UserData[key] = value


func getExtPath(ext: String):
	return ext_path.get(ext, null)


# === Сброс данных ===

func RestoreData():
	SettingsList = BaseSettingsList.duplicate()
	save_config()


func RestoreUserData():
	UserData = BaseUserData.duplicate()
	save_user_data()
