extends Node
class_name SettingFilling


const PARAMETERS = {
	"Resolution": "Settings up the window size of this game. 16x9 only",
	"Framerate": "Mostly affects on UI and *minigames*. IT WON'T SPEED UP VIDEO!"
}

func _ready() -> void:
	pass

func get_description(key:String) -> String:
	return PARAMETERS[key]
