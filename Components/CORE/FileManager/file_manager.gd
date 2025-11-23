extends Node
class_name FileManager

const FILTERS = {
	new_project = ["*.mp3", "*.mp4", "*.mkv", "*.ogv"],
	open_existing = ["*.json", "*.txt"],
	image = ["*.png", "*.jpg", "*.jpeg", "*.webp"],
	all = ["*"]
}

func open(callback: Callable, filter_type: String = "all", dir: String = "res://") -> FileDialog:
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES

	if filter_type != "all" and FILTERS.has(filter_type):
		file_dialog.filters = PackedStringArray(FILTERS[filter_type])

	file_dialog.current_dir = dir
	file_dialog.title = "Choose files"

	file_dialog.files_selected.connect(func(paths: PackedStringArray):
		callback.call(paths)
		file_dialog.queue_free()
	)
	file_dialog.canceled.connect(file_dialog.queue_free)
	
	return file_dialog
