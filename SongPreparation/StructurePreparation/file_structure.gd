extends Node

class_name FileStructurePrep


func folder_init(root_folder_path: String) -> String:
	var dir = FileAccess.open(root_folder_path, FileAccess.READ)
	
	if dir.exists():
		if dir.get_parent_files().size() > 0:
			var confirmation = await show_confirmation_dialog()
			if confirmation == false:
				Debugger.debug("file__structure.gd", "folder_init()", "Rejected")
				return ""
			else:
				dir.remove_subdirectory(root_folder_path, true)
				Debugger.debug("file__structure.gd", "folder_init()", "Folder deleted")
		dir = FileAccess.open(root_folder_path, FileAccess.READ)
	else:
		var result = dir.make_dir_recursive(root_folder_path)
		if result != OK:
			Debugger.error("file__structure.gd", "folder_init()", "New folder creation failed!")
			return ""

	var franchise_folder = root_folder_path + "/Francise"
	if not dir.dir_exists(franchise_folder):
		dir.make_dir(franchise_folder)

	create_file_if_not_exists(franchise_folder + "/album_descriptions.json")
	
	var season_folder = franchise_folder + "/Season1"
	if not dir.dir_exists(season_folder):
		dir.make_dir(season_folder)
	
	create_file_if_not_exists(season_folder + "/about.json")

	var song_folder = season_folder + "/Power"
	if not dir.dir_exists(song_folder):
		dir.make_dir(song_folder)

	create_file_if_not_exists(song_folder + "/config.json")

	return song_folder


func create_file_if_not_exists(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE)
	if file.error() == OK:
		return
	var new_file = FileAccess.open(file_path, FileAccess.WRITE)
	if new_file.error() != OK:
		Debugger.error("file__structure.gd", "folder_init()", "Failed creation of file: " + file_path)
	new_file.close()


func show_confirmation_dialog() -> bool:
	var conf_dial = ConfirmationDialog.new()
	conf_dial.title = "Confirmation"

	var label = Label.new()
	label.text = "Are you sure you want to delete this item?"
	conf_dial.add_child(label)

	conf_dial.add_button("Delete", true)
	conf_dial.add_cancel_button("Cancel")

	conf_dial.connect("confirmed", Callable(self, "_on_confirmed"))
	conf_dial.connect("canceled", Callable(self, "_on_canceled"))

	conf_dial.popup_centered()

	await conf_dial.confirmed
	conf_dial.queue_free()

	return true


func _on_confirmed():
	Debugger.debug("file__structure.gd", "folder_init()", "User confirmed the action")
	complete_action()
func _on_canceled():
	Debugger.debug("file__structure.gd", "folder_init()", "User canceled the action")
func complete_action():
	Debugger.debug("file__structure.gd", "folder_init()", "Action completed!")
