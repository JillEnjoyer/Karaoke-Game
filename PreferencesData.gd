extends Node

var PreferedSaveLoc = "res://Preferences/"

var BaseSettingsList = {
	"resolution": Vector2(1920, 1080),
	"language": "ENG",
	"window_mode": "Window",
	"overall_volume": 100,
	"mic_status": "Unsupported",
	"framerate_lock": 75,
	"countdown_time": 4,
	"debugger_enabled": false
}

var SettingsList = {
	"resolution": Vector2(1920, 1080),
	"language": "ENG",
	"window_mode": "Window",
	"overall_volume": 100,
	"mic_status": "Unsupported",
	"framerate_lock": 75,
	"countdown_time": 4,
	"debugger_enabled": true
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func getData(Setting: String):
	var value
	if SettingsList and SettingsList[Setting]:
		value = SettingsList[Setting]
	else:
		value = BaseSettingsList[Setting]
	
	print(value)
	return value

func setData(Setting: String):
	if not SettingsList and not SettingsList[Setting]:
		RestoreData()
		
	if 

func RestoreData():
	SettingsList = BaseSettingsList
