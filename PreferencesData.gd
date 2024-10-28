extends Node

var PreferedSaveLoc = "res://Preferences/"

var BaseSettingsList = {
	"ResolutionX": Vector2(1920, 1080),
	"Language": "ENG",
	"WindowMode": "Window",
	"OverallVolume": 100,
	"MicStatus": "Unsupported",
	"FramerateLock": 75,
	"CountDownTime": 4
}

var SettingsList = {
	"ResolutionX": Vector2(1920, 1080),
	"Language": "ENG",
	"WindowMode": "Window",
	"OverallVolume": 100,
	"MicStatus": "Unsupported",
	"FramerateLock": 75,
	"CountDownTime": 4
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

func RestoreData():
	SettingsList = BaseSettingsList
