extends Node

var global_path_to_folder = "D:/MusicLibrary"

var link_name_in_project = "Music"

func _ready():
	if OS.has_feature("windows"):
		create_hardlink_windows()
	else:
		print("Hard links are only supported on Windows with mklink /J.")
		print("On Linux/macOS, please use symlinks (modify script if needed).")

func create_hardlink_windows():
	var project_root = ProjectSettings.globalize_path("res://")
	var link_path = project_root + "/" + link_name_in_project

	var dir = DirAccess.new.call()
	if dir.dir_exists(link_path):
		print("Hard link already exists:", link_path)
		return
	
	var command = 'mklink /J "{}" "{}"'.format(link_path.replace("/", "\\"), global_path_to_folder.replace("/", "\\"))

	var result = OS.execute("cmd", ["/c", command], [])
	
	if result == OK:
		print("Hard link created successfully:", link_path)
	else:
		print("Failed to create hard link. Ensure paths are correct and files are accessible.")
