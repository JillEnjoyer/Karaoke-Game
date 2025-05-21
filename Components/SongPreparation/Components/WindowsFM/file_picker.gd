extends Node
class_name FilePicker

var file_manager = FileManager.new()

var file_array: PackedStringArray = []

func open_file_picker(start_path: String = OS.get_executable_path().get_base_dir()) -> PackedStringArray:
	var file_array: String = ""
	if true:
		return open_windows_file_picker(start_path)
	else:
		return use_compability_fm(start_path)
	return []

 
func open_windows_file_picker(start_path) -> PackedStringArray:
	var script_path = ProjectSettings.globalize_path("res://Components/SongPreparation/Components/WindowsFM/file_picker.ps1")
	var output := []
	var error := false

	var args = [
		"/c",
		"powershell",
		"-ExecutionPolicy", "Bypass",
		"-File", "\"" + script_path + "\"",
		"-initialDir", "\"" + start_path + "\""
	]
	var exit_code := OS.execute("cmd", args, output, true, error)
	var files: PackedStringArray = []

	if exit_code == 0 and output.size() > 0:
		for line in output:
			for path in line.split("\n"):
				path = path.strip_edges()
				if path != "" and path != "True":
					path = path.replace("\\", "/")
					files.append(path)
	else:
		Debugger.error("Files are not chosen or an error occurred: " + str(error))
		files = []
	return files


func use_compability_fm(start_path):
	var file_array: PackedStringArray = []
	var fm = file_manager.open(_on_files_selected, "new_project")
	UIManager.new_child(fm, self)
	fm.popup_centered_ratio(0.8)


func _on_files_selected(paths: PackedStringArray):
	file_array = paths
