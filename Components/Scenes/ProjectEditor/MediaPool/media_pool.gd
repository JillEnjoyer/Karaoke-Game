extends Control

@onready var file_list_container = $ScrollContainerFM/VBoxContainer
@onready var chosen_list_container = $ScrollContainerCI/VBoxContainer

var current_path: String = "res://Catalog/"
var dir: DirAccess
enum TrackRole { NONE, VIDEO, ACAPELLA, INSTRUMENTAL, DRUMS, BASS, INSTRUMENTS }
var chosen_files: Dictionary = {} 

var MediaPoolItemScene = UIManager.get_desired_node("MediaPoolItem")

func _ready():
	dir = DirAccess.open(current_path)
	update_file_list()

func update_file_list():
	clear_children(file_list_container)
	if not dir: return

	var entries = dir.get_files() + dir.get_directories()
	for file_name in entries:
		var full_path = current_path.path_join(file_name)
		var is_folder = DirAccess.dir_exists_absolute(full_path)
		var tile = create_tile(file_name, is_folder)
		file_list_container.add_child(tile)

func create_tile(file_name: String, is_folder: bool) -> Button:
	var button = Button.new()
	button.text = file_name + ("/" if is_folder else "")
	button.custom_minimum_size = Vector2(0, 40)
	button.connect("pressed", Callable(self, "_on_tile_pressed").bind(file_name, is_folder))
	return button

func _on_tile_pressed(file_name: String, is_folder: bool):
	var full_path = current_path.path_join(file_name)
	if is_folder:
		current_path = full_path
		dir = DirAccess.open(current_path)
		update_file_list()
		return

	_add_file_to_pool(file_name, full_path)


func add_files(files_array: Array):
	for file_data in files_array:
		# file_data contains path, type, duration
		var file_name = file_data.path.get_file()
		_add_file_to_pool(file_name, file_data.path)

func _add_file_to_pool(file_name: String, path: String):
	if chosen_files.has(path):
		Debugger.debug("File already in pool: " + file_name)
		return

	var ext = path.get_extension().to_lower()
	var base_type = "audio"
	var current_role = TrackRole.INSTRUMENTAL

	if ext in ["mp4", "mkv", "avi", "webm"]:
		base_type = "video"
		current_role = TrackRole.VIDEO
	elif ext in ["mp3", "wav", "ogg", "flac"]:
		base_type = "audio"
		current_role = TrackRole.INSTRUMENTAL

	var duration = MetadataGetter.get_duration(path)

	chosen_files[path] = {
		"name": file_name,
		"path": path,
		"base_type": base_type,
		"role": current_role,
		"duration": duration
	}

	var pool_item = MediaPoolItemScene.instantiate()
	chosen_list_container.add_child(pool_item)
	pool_item.setup(self, chosen_files[path])


func update_file_role(path: String, new_role: int):
	if chosen_files.has(path):
		chosen_files[path]["role"] = new_role

func clear_children(container: Control):
	for child in container.get_children():
		child.queue_free()
