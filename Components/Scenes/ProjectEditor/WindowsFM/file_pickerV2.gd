extends Control
class_name FilePickerV2

@onready var picker := FileDialog.new()

func _ready() -> void:
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.use_native_dialog = true 
	picker.filters = ["*.* ; All Files"]
	picker.title = "Choose Files"
	picker.ok_button_text = "Open"
	picker.files_selected.connect(_on_files_selected)
	print(self.get_parent().name)
	add_child(picker)

func open_native_picker() -> void:
	picker.popup()

func _on_files_selected(files: PackedStringArray) -> void:
	print("Choosen:", files)
