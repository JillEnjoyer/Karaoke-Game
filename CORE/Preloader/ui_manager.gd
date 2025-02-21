extends Node

@onready var default_parent = get_node("/root/ViewportBase/SubViewportContainer/SubViewport")

var preloaded_scenes = {}

func _ready():
	for key in SCENES.keys():
		preloaded_scenes[key] = load(SCENES[key])

const SCENES = {
	"main_menu": "res://MainMenu/MainMenu.tscn",
	"voice_channel_control_scene": "res://PlayerScene/VoiceChannelControl/VoiceChannelControl.tscn",
	"pause_menu_scene": "res://PlayerScene/PauseMenu/PauseMenu.tscn",
	"timer_scene": "res://PlayerScene/Timer/TimerScene.tscn",
	"time_slider": "res://PlayerScene/Timer/TimeSlider.tscn"
	
}

func show_ui(scene_name: String, desired_parent: String = "") -> Node:
	if not preloaded_scenes.has(scene_name):
		Debugger.error("ss", "show_ui()", "Error: Scene is not found in the list!")
		return null

	var parent = default_parent
	if desired_parent != "":
		if default_parent.has_node(desired_parent):
			parent = default_parent.get_node(desired_parent)
		else:
			Debugger.error("ss", "show_ui()", "Error: Parent object '" + desired_parent + "' is not found!")
			return null

	var scene_instance = preloaded_scenes[scene_name].instantiate()
	parent.add_child(scene_instance)
	scene_instance.owner = parent
	return scene_instance
