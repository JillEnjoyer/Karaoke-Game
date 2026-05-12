extends Control

signal timeline_changed

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer

@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames
@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines

@onready var h_scroll = $HSplitContainer/TimelinePanel/TimeBar/HScrollBar
@onready var time_pointer = $HSplitContainer/TimelinePanel/TimePointer

@onready var drop_zone = $DropZone

var TrackHeaderScene = UIManager.get_desired_node("TrackHeader")
var ControllerWrapperScene = UIManager.get_desired_node("ControllerWrapper")

var px_to_sec_ratio: float = (70.0 * 16.0 / 9.0) / 5.0 
var context_menu: PopupMenu
var _active_idx: int = -1


func _ready() -> void:
	drop_zone.visible = false
	drop_zone.timeline = self

	_init_context_menu()
	_sync_scrolling()
	
	if time_pointer:
		time_pointer.pointer_moved.connect(_on_time_pointer_moved)
		time_pointer.move_timeline.connect(_on_timeline_move_requested)

func _init_context_menu():
	context_menu = PopupMenu.new()
	add_child(context_menu)
	context_menu.index_pressed.connect(_on_menu_item_selected)

func _sync_scrolling():
	var v_scroll_names = name_scroll_container.get_v_scroll_bar()
	var v_scroll_time = timeline_scroll_container.get_v_scroll_bar()
	
	v_scroll_names.value_changed.connect(func(val): v_scroll_time.value = val)
	v_scroll_time.value_changed.connect(func(val): v_scroll_names.value = val)


func add_channel(node_name: String, path: String, duration: float, type: String):
	# 1. Left part (Header)
	var header = TrackHeaderScene.instantiate()
	vbox_names.add_child(header)
	#header.setup(node_name, type)
	header.call_deferred("setup", [node_name, type])
	
	# RMC connection on header
	header.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_track_menu(header.get_index(), type)
	)

	# 2. Right part (Wrapper)
	var wrapper = ControllerWrapperScene.instantiate()
	wrapper.add_tree_objects(time_pointer, h_scroll)
	vbox_timelines.add_child(wrapper)
	
	wrapper.node_name = node_name
	wrapper.initial_path = path
	wrapper.node_type = type
	wrapper.total_duration = duration
	wrapper.px_to_sec_ratio = px_to_sec_ratio
	
	if wrapper.has_method("init_visuals"):
		wrapper.init_visuals()
	
	wrapper.connect("segment_changed", func(): timeline_changed.emit())
	
	timeline_changed.emit()


func _show_track_menu(idx: int, type: String):
	_active_idx = idx
	context_menu.clear()
	context_menu.add_item("Move higher", 0)
	context_menu.add_item("Move lower", 1)
	context_menu.add_separator()
	
	if type == "acapella":
		context_menu.add_item("Subtitle editor (Vosk)", 2)
		context_menu.add_item("Set character", 3)
	
	context_menu.add_separator()
	context_menu.add_item("Delete track", 4)
	
	context_menu.position = get_viewport().get_mouse_position()
	context_menu.show()

func _on_menu_item_selected(id: int):
	if _active_idx == -1: return
	
	var header = vbox_names.get_child(_active_idx)
	var wrapper = vbox_timelines.get_child(_active_idx)
	
	match id:
		0: # Up
			if _active_idx > 0:
				vbox_names.move_child(header, _active_idx - 1)
				vbox_timelines.move_child(wrapper, _active_idx - 1)
		1: # Down
			if _active_idx < vbox_names.get_child_count() - 1:
				vbox_names.move_child(header, _active_idx + 1)
				vbox_timelines.move_child(wrapper, _active_idx + 1)
		4: # Delete
			header.queue_free()
			wrapper.queue_free()
			timeline_changed.emit()
	
	_active_idx = -1


# --- Drag & Drop ---
func _notification(what):
	match what:
		NOTIFICATION_DRAG_BEGIN:
			if _is_valid_drag():
				drop_zone.visible = true
		NOTIFICATION_DRAG_END:
			drop_zone.visible = false


func _is_valid_drag() -> bool:
	var data = get_viewport().gui_get_drag_data()
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "media_file"


func _can_drop_data(_at_position, data) -> bool:
	Debugger.debug("Called...")
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "media_file"


func _drop_data(_pos, data):
	Debugger.debug("Then called?")
	var type_str = "instrumental" 
	match int(data.role):
		2: # Acapella
			type_str = "acapella"
		1: # Video
			type_str = "video"
		_: # Others (3, 4, 5...)
			type_str = "instrumental"
	
	add_channel(
		data.node_name, 
		data.path, 
		data.duration, 
		type_str
	)


func export_project_configs() -> Dictionary:
	var export_data = {
		"files": {"acapella": {}, "instrumental": {}, "video": {}},
		"characters": []
	}
	
	for wrapper in vbox_timelines.get_children():
		if not wrapper.has_method("prepare_export_timecodes"): continue
		
		var track_info = {
			"path": wrapper.initial_path,
			"jumpers": wrapper.prepare_export_timecodes()
		}
		
		match wrapper.node_type:
			"acapella":
				export_data["files"]["acapella"][wrapper.node_name] = track_info
				if not wrapper.node_name in export_data["characters"]:
					export_data["characters"].append(wrapper.node_name)
			"instrumental":
				export_data["files"]["instrumental"][wrapper.node_name] = track_info
			"video":
				export_data["files"]["video"] = track_info
				
	return export_data


func _on_time_pointer_moved(pointer_time: float) -> void:
	pass

func _on_timeline_move_requested(delta_move_in_pix: int) -> void:
	var new_h_scroll_value = timeline_scroll_container.scroll_horizontal + delta_move_in_pix
	timeline_scroll_container.scroll_horizontal = clamp(new_h_scroll_value, h_scroll.min_value, h_scroll.max_value)
