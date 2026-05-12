extends Control

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer
@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames

@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines
@onready var vbox_ruler = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines/VBoxRuler

@onready var h_scroll = $HSplitContainer/TimelinePanel/TimeBar/HScrollBar
@onready var v_scroll = $VScrollBar
@onready var name_panel = $HSplitContainer/NamePanel

@onready var time_pointer = $HSplitContainer/TimelinePanel/TimePointer

@onready var time_lbl_start = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelStart
@onready var time_lbl_end = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelEnd

var previous_start_time: float = 0.0
var previous_end_time: float = 0.0

#0, 1, 2 pos...if 0 is deleted then others shold move up - they're going in order as seen
var tracks_info := []
var track_example: Dictionary = {
	"name": "", # name of the track - shown on the left side - name of the material like: sth.mp4
	"path": "", # absolute path to the file: C:/Users/download/sth.mp4
	"type": "", # Video/Instrumental/Acapella/Character
	"object": "", # reference to the object in scene tree that holds the media and config
	"duration": 0 # total duration in seconds: object1_offset + object1 - object1_left_cutoff - object1_right_cutoff + objectN_offset + ...
}


func _ready():
	var max_name_width = 0
	#var font = ThemeDB.fallback_font
	
	name_panel.custom_minimum_size.x = max_name_width + 20
	
	name_scroll_container.set_v_scroll(0)
	timeline_scroll_container.set_v_scroll(0)

	#update_scrollbars()
	#update_time_labels()
	#update_scroll_range()
	# time_pointer.connect("pointer_moved", Callable(self, "_on_time_pointer_moved"))
	time_pointer.connect("move_timeline", Callable(self, "_on_timeline_move_requested"))

	h_scroll.connect("value_changed", Callable(self, "_on_h_scroll_changed"))

	add_channel("ruler", "", 300.0) # 5 minutes ruler


func _format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60.0
	var sec = int(seconds) % 60
	Debugger.debug("Formatted time: " + "%02d:%02d" % [minutes, sec] + " Total: %02d seconds" % [seconds])
	return "%02d:%02d" % [minutes, sec]


func setup_current_time() -> void:
	# time goes from time pointer
	pass
	#var time_string: String = ValueConverter.time_to_display_string(time)


func setup_total_time() -> void:
	var total_time := 0.0
	for child in vbox_timelines.get_children():
		if child.has_method("get_total_duration"):
			total_time += child.get_total_duration()
	#setup_needed_width(total_time)

"""
func _draw():
	var px_to_sec_ratio = (70.0 * 16.0 / 9.0) / 5.0 # for now
	var px_per_sec = px_to_sec_ratio

	var scroll_x = h_scroll.value
	var screen_width = size.x

	var start_sec = max(0, floor(scroll_x / px_per_sec))
	var end_sec = ceil((scroll_x + screen_width) / px_per_sec)

	for s in range(start_sec, end_sec + 1):
		var x_pos = s * px_per_sec - scroll_x
		
		if s % 10 == 0:
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, 25), Color.WHITE, 2.0, true)
			var time_str = "%02d:%02d" % [int(s / 60), int(s) % 60]
			draw_string(get_theme_default_font(), Vector2(x_pos + 5, 20), time_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
			
		elif s % 5 == 0:
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, 15), Color.GRAY, 1.0, true)
			
		elif px_per_sec > 5: 
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, 7), Color.DARK_GRAY, 1.0, true)
"""
func _on_h_scroll_changed(value: float):
	Debugger.debug("Horizontal scroll changed: " + str(value))
	timeline_scroll_container.scroll_horizontal = value
	update_time_labels()


""" 
func setup_needed_width(duration: float) -> void:
	var needed_width = duration * 50.0 # 50 pixels per second
	if needed_width < timeline_scroll_container.size.x:
		needed_width = timeline_scroll_container.size.x
	vbox_timelines.custom_minimum_size.x = needed_width
	update_scroll_range()
	update_time_labels()
"""


func update_scroll_range():
	var total_width = vbox_timelines.get_combined_minimum_size().x
	var visible_width = timeline_scroll_container.size.x
	h_scroll.max_value = max(0, total_width - visible_width)
	h_scroll.page = visible_width


func add_channel(node_name: String, path: String, duration: int):
	var name_box = PanelContainer.new()
	name_box.custom_minimum_size = Vector2(name_panel.custom_minimum_size.x, 50)

	var name_label = Label.new()
	name_label.text = node_name
	name_label.size_flags_horizontal = Control.SIZE_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(100, 70)
	name_box.add_child(name_label)
	vbox_names.add_child(name_box)

	#var controller_wrapper = UIManager.show_ui("controller_wrapper", desired_parent)
	var controller_wrapper = UIManager.get_desired_node("ControllerWrapper").instantiate()
	controller_wrapper.add_tree_objects(time_pointer, h_scroll)
	
	vbox_timelines.add_child(controller_wrapper)
	controller_wrapper.init(node_name, path, node_name, duration)
	
	update_time_labels()
	update_scroll_range() # Is this needed here?


## start_time - time of pointer
## end_time - max of all total_durations
func update_time_labels(start_time: float = -1.0, end_time: float = -1.0):
	if start_time == previous_start_time and end_time == previous_end_time:
		return
	if start_time == -1.0:
		start_time = h_scroll.value
	if end_time == -1.0:
		end_time = calculate_actual_duration()
	
	#var end_time = h_scroll.value + (timeline_scroll_container.size.x / 50.0)
	end_time = timeline_scroll_container.size.x / 50.0
	
	time_lbl_start.text = ValueConverter.time_to_display_string(start_time)
	time_lbl_end.text = ValueConverter.time_to_display_string(end_time)


func calculate_actual_duration() -> float: # change!
	return 1.0
	var max_duration = 0.0
	for child in vbox_timelines.get_children():
		if child.has_method("get_total_duration"):
			var child_duration = child.get_total_duration()
			if child_duration > max_duration:
				max_duration = child_duration
	return max_duration


func update_scrollbars():
	return
	await get_tree().process_frame
	v_scroll.max_value = max(0, vbox_names.get_combined_minimum_size().y - name_scroll_container.size.y)
	h_scroll.max_value = max(0, vbox_timelines.get_combined_minimum_size().x - name_scroll_container.size.x)


func _on_v_scroll_bar_value_changed(value: float) -> void:
	name_scroll_container.set_v_scroll(value)
	timeline_scroll_container.set_v_scroll(value)
func _on_h_scroll_bar_value_changed(value: float) -> void:
	timeline_scroll_container.set_h_scroll(value)


func _on_time_pointer_moved(pointer_time: float) -> void:
	# Update any relevant UI or state based on the new pointer time
	Debugger.debug("Time Pointer moved to time: " + str(pointer_time) + " seconds")
	
	
func _on_timeline_move_requested(delta_move_in_pix: int) -> void:
	# Move the timeline scroll based on the delta move requested by the time pointer
	var new_h_scroll_value = timeline_scroll_container.scroll_horizontal + delta_move_in_pix
	## Change to h_scroll object in future
	timeline_scroll_container.scroll_horizontal = clamp(new_h_scroll_value, h_scroll.min_value, h_scroll.max_value)


func import_choosen_files(files: Array):
	for file in files:
		add_channel(file["type"], file["path"], file["duration"])


func export_project_configs() -> Dictionary:
	return {}
	"""
	export_data = {
		"tracks": [
			{
				"name": "Alastors Offer.mp4",
				"path": "C:/Users/Downloads/", # absolute path to the file (mostly in the catalog path)
				"type": "Video",
				"object": "Pointer to the object in scene tree",
				"duration": X.XX, # total duration in seconds
				"timecodes": [ {start_from: 0.0}, {from_time: x.x, to_time: y.y}, ... ] # Data that defines every file config
			},
			...
		]
	}

	"""
	
	var export_data: Dictionary = {}
	export_data["tracks"] = []
	
	for child in vbox_timelines.get_children():
		if child.has_method("prepare_export_timecodes"):
			var segment_data = child.export_segment_data()
			export_data["tracks"].append(segment_data)
	
	return export_data



func _drop_data(_pos, data):
	if data.get("type") == "media_file":
		add_channel(data.node_name, data.path, data.duration)
