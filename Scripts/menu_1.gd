extends Node2D

var scene_paths = {
	"MainMenu": "res://MainMenu.tscn"
}

var current_scene = null

func _ready():
	_show_scene("MainMenu")
	pass

func _show_scene(name: String):
	if current_scene:
		current_scene.queue_free()
	
	var scene_path = scene_paths[name]
	var new_scene = load(scene_path).instantiate()
	add_child(new_scene)
	current_scene = new_scene
	print("Scene loaded:", name)

func _print_child_nodes():
	print("Current child nodes:")
	for child in get_children():
		print("- " + str(child.name))
