extends Control
## Holds ControllerWrappers
## Controls their position in vertical/horizontal scroll containers
## Updates time labels and scrollbars

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer
@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames
@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines
@onready var h_scroll = $HSplitContainer/TimelinePanel/TimeBar/HScrollBar
@onready var v_scroll = $VScrollBar
@onready var name_panel = $HSplitContainer/NamePanel

@onready var time_pointer = $HSplitContainer/TimelinePanel/TimePointer

@onready var time_lbl_start = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelStart
@onready var time_lbl_end = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelEnd

## vars
var previous_start_time: float = 0.0
var previous_end_time: float = 0.0

#0, 1, 2 pos...if 0 is deleted then others shold move up - they're going in order as seen
var tracks_info := []
var track_example: Dictionary = {
	"name": "", # name of the track - shown on the left side - name of the material like: sth.mp4
	"path": "", # absolute path to the file: C:/Users/download/sth.mp4
	"type": "", # Video/Instrumental/Acapella/Character
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


func _format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60.0
	var sec = int(seconds) % 60
	Debugger.debug("Formatted time: " + "%02d:%02d" % [minutes, sec] + " Total: %02d seconds" % [seconds])
	return "%02d:%02d" % [minutes, sec]


func setup_current_time() -> void:
	# time goes from time pointer
	pass
	#var time_string: String = _format_time(time)


func setup_total_time() -> void:
	var total_time := 0.0
	for child in vbox_timelines.get_children():
		if child.has_method("get_total_duration"):
			total_time += child.get_total_duration()
	#setup_needed_width(total_time)


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


func _on_h_scroll_changed(value: float):
	Debugger.debug("Horizontal scroll changed: " + str(value))
	timeline_scroll_container.scroll_horizontal = value
	update_time_labels()


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

	var controller_wrapper = UIManager.get_desired_node("controller_wrapper").instantiate()
	
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
	
	time_lbl_start.text = _format_time(start_time)
	time_lbl_end.text = _format_time(end_time)


func calculate_actual_duration() -> float: # change!
	var max_duration = 0.0
	for child in vbox_timelines.get_children():
		if child.has_method("get_total_duration"):
			var child_duration = child.get_total_duration()
			if child_duration > max_duration:
				max_duration = child_duration
	return max_duration


func update_scrollbars():
	await get_tree().process_frame
	v_scroll.max_value = max(0, vbox_names.get_combined_minimum_size().y - name_scroll_container.size.y)
	h_scroll.max_value = max(0, vbox_timelines.get_combined_minimum_size().x - name_scroll_container.size.x)


func _on_v_scroll_bar_value_changed(value: float) -> void:
	name_scroll_container.set_v_scroll(value)
	timeline_scroll_container.set_v_scroll(value)
func _on_h_scroll_bar_value_changed(value: float) -> void:
	timeline_scroll_container.set_h_scroll(value)


"""
chosen_files.append({
		"path": path,
		"type": type,
		"duration": duration
	})

chosen_files = [
	{"path": path, "type": type, "duration": duration},
	{"path": path, "type": type, "duration": duration}
]
"""

func import_choosen_files(files: Array):
	for file in files:
		add_channel(file["type"], file["path"], file["duration"])
