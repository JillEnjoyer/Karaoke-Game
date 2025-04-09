extends Node

@onready var default_parent = get_node("/root/ViewportBase/SubViewportContainer/SubViewport")
@onready var core = get_node("/root")

var preloaded_scenes = {}

const SCENES = {
	"main_menu": "res://MainMenu/MainMenu.tscn",
	"voice_channel_control_scene": "res://PlayerScene/VoiceChannelControl/VoiceChannelControl.tscn",
	"pause_menu_scene": "res://PlayerScene/PauseMenu/PauseMenu.tscn",
	"timer_scene": "res://PlayerScene/Timer/TimerScene.tscn",
	"time_slider": "res://PlayerScene/Timer/TimeSlider.tscn",
	"web_socket": "res://WebSocket/web_socket.tscn",
	"player_scene": "res://PlayerScene/PlayerScene/PlayerScene.tscn",
	"catalog": "res://CatalogSystem/Catalog/Catalog.tscn",
	"song_prep_scene": "res://SongPreparation/SongPreparationScene.tscn",
	"settings": "res://Settings/Settings.tscn",
	"preset_panel": "res://CatalogSystem/Catalog/Presetting.tscn"
}


func _ready():
	for key in SCENES.keys():
		preloaded_scenes[key] = load(SCENES[key])


func show_ui(scene_name: String, desired_parent: String = "") -> Node:
	if not preloaded_scenes.has(scene_name):
		Debugger.error("ss", "show_ui()", "Error: Scene is not found in the list!")
		return null
	
	var parent = get_needed_parent(desired_parent)

	var scene_instance = preloaded_scenes[scene_name].instantiate()
	parent.add_child(scene_instance)
	scene_instance.owner = parent
	return scene_instance


func new_child(node, desired_parent: String = ""):
	var parent = get_needed_parent(desired_parent)
	parent.add_child(node)


func get_needed_parent(desired_parent):
	var parent = ""
	if desired_parent == "core":
		parent = core
	else:
		parent = default_parent
		
	if desired_parent != "" and desired_parent != "core":
		if default_parent.has_node(desired_parent):
			parent = default_parent.get_node(desired_parent)
		else:
			Debugger.error("ss", "show_ui()", "Error: Parent object '" + desired_parent + "' is not found!")
			return null
	return parent


func remove_child_from_tree(removable_node: String, node_path: String = "") -> void:
	var parent = default_parent if node_path == "" else default_parent.get_node(node_path)
	if parent and parent.has_node(removable_node):
		parent.remove_child(parent.get_node(removable_node))
	else:
		Debugger.error("ui_manager.gd", "remove_child_from_tree()", "There is no parent: '" + parent.name + "' or no removable node: '" + removable_node + "'")
func cleanup_tree() -> void:
	for child in default_parent.get_children().duplicate():
		default_parent.remove_child(child)
		child.queue_free()
	Debugger.info("ui_manager.gd", "cleanup_tree()", "Tree is cleaned")
