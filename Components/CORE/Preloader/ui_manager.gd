extends Node

@onready var default_parent = get_node("/root/ViewportBase/SubViewportContainer/SubViewport")
@onready var core = get_node("/root")

var scene_registry = SceneRegistry.new()

var preloaded_scenes = {}
var found_scenes := {}


func _ready():
	found_scenes = scene_registry.build_scene_map()
	for key in found_scenes.keys():
		preloaded_scenes[key] = load(found_scenes[key])


## Add_child from already preloaded list of scene elemenets (much faster)
func show_ui(scene_name: String, desired_parent = "") -> Node:
	if not preloaded_scenes.has(scene_name):
		Debugger.error("ss", "show_ui()", "Error: Scene is not found in the list!")
		return null
	
	var parent: Node = null
	if typeof(desired_parent) == TYPE_OBJECT and desired_parent is Node:
		parent = desired_parent
	else:
		parent = get_needed_parent(desired_parent)

	var scene_instance = preloaded_scenes[scene_name].instantiate()
	parent.add_child(scene_instance)
	scene_instance.owner = parent
	return scene_instance


## by a string name from preloaded scenes we return a copy (instantiate() is happening after)
func get_desired_node(name: String) -> PackedScene:
	if not preloaded_scenes.has(name):
		Debugger.error("ss", "show_ui()", "Error: Scene is not found in the list!")
		return null
	return preloaded_scenes[name]


## Add_child of already .instantiate() object. Slower but simpler
func new_child(node: Node, desired_parent):
	var parent: Node = null
	if typeof(desired_parent) == TYPE_OBJECT and desired_parent is Node:
		parent = desired_parent
	else:
		parent = get_needed_parent(desired_parent)
	if parent != null:
		parent.add_child(node)
	else:
		Debugger.error("UIManager", "new_child()", "Failed to add child: parent is null.")


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
