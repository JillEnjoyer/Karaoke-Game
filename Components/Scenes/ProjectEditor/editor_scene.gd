extends Control

@onready var timeline = $Timeline
@onready var media_pool = $MediaPool
@onready var media_player = $MediaPlayer

var last_exported_config: Dictionary = {}
var is_dirty: bool = false

func _ready() -> void:
	media_player.editor_mode = true
	
	if timeline.has_signal("timeline_changed"):
		timeline.timeline_changed.connect(_on_timeline_changed)
	
	media_pool.update_file_list()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		toggle_playback()
	
	#if event is InputEventMouseButton:
	#	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
	#		print("LMC detected!")


func toggle_playback() -> void:
	if media_player.is_playing:
		media_player.pause()
		return

	var current_config = timeline.export_project_configs()
	
	if _check_needs_hard_reinit(current_config):
		Debugger.debug("HARD RE-INIT: File list changed. Reloading resources...")
		media_player.hard_reinit(current_config)
		is_dirty = false
	elif is_dirty:
		Debugger.debug("SOFT RE-INIT: Same files, Updating jumpers...")
		media_player.soft_reinit(current_config)
		is_dirty = false
	
	last_exported_config = current_config
	
	var start_pos_px = timeline.time_pointer.position.x
	var start_time = start_pos_px / timeline.px_to_sec_ratio
	
	media_player.play_from(start_time)


func _check_needs_hard_reinit(new_config: Dictionary) -> bool:
	if last_exported_config.is_empty():
		return true
		
	var old_files = _get_file_paths_list(last_exported_config)
	var new_files = _get_file_paths_list(new_config)
	
	return old_files != new_files


func _get_file_paths_list(config: Dictionary) -> Array:
	var paths = []
	var files = config.get("files", {})
	
	for category in ["acapella", "instrumental"]:
		var cat_dict = files.get(category, {})
		for key in cat_dict:
			paths.append(cat_dict[key].get("path", ""))
			
	if files.has("video"):
		paths.append(files["video"].get("path", ""))
		
	paths.sort()
	return paths


func _on_timeline_changed() -> void:
	is_dirty = true

func switch_player_scene_mode() -> void:
	pass


func _on_fm_btn_pressed() -> void:
	Debugger.debug("FM is opened")
	open_fm("all")

func open_fm(type: String) -> void:
	var file_picker = FilePicker.new()
	files_selected(file_picker.open_file_picker())


func files_selected(paths: PackedStringArray):
	Debugger.debug("Choosen files: " + str(paths))
	var chosen_files := []
	for path in paths:
		var type = TypeGetter.get_file_type(path)
		chosen_files.append({
		"path": path,
		"type": type,
		"duration": MetadataGetter.get_duration(path)
	})
	media_pool.add_files(chosen_files)
