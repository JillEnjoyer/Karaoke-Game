# controller_wrapper.gd
extends Control

@onready var time_pointer = $"../../../../TimePointer"
@onready var offset_controller = UIManager.get_desired_node("offset_controller")

var thumbnail_generator = ThumbnailGenerator.new()
var waveform_generator = WaveformGenerator.new()
var context_menu = ContextMenuManager.new()
var dot_drawer = ""
var value_converter = ValueConverter.new()

var ffmpeg_path = PreferencesData.get_ext_path("ffmpeg")

var node_name := ""
var initial_path := ""
var node_type := ""
var total_duration := 1.0

var px_per_second := 1.0
var _last_segment_id := 0
var bind_threshold := 0.1

var segments := [] # only nodes of OffsetController

var timecodes_for_export: Array = [
	# {start_from: 0.0},
	# {from_time: 26.4214, to_time: 45.1234},
	# {from_time: 60.0, to_time: 75.0} # backwards it goes from "to_time" to "from_time"
]


func _ready() -> void:
	pass


func init(obj_name: String, file_path: String, type: String, duration: float) -> void:
	self.node_name = obj_name
	self.initial_path = file_path
	self.node_type = type
	self.total_duration = duration
	
	add_segment(0, duration)


func import_initial_data(type: String, path: String):
	if type == "video":
		create_thumbnails(path)
	elif type == "audio":
		create_waveform(path)
	elif type == "subtitles": ## subtitles should be connected to acapella object(s)
		draw_dots()
	elif type == "mask": ## TODO: in the future it will be connected to subtitles object
		pass

## Onetime setup methods
func create_thumbnails(path: String):
	var data = thumbnail_generator.generate_thumbnails(path, value_converter.timestamp)
	var textures = data.get("thumbnails", [])
	total_duration = data["metadata"].get("duration", 0.0)
	segments[0].apply_thumbnail_data(textures, total_duration)
func create_waveform(path: String):
	self.size.x = 2100.0
	self.size.y = 70.0
	var texture = waveform_generator.load_waveform_image(path, ffmpeg_path, self.size.x, self.size.y, "black")
	segments[0].apply_thumbnail_data([texture], total_duration)
func draw_dots():
	Debugger.warning("Not implemented yet")


func _resolve_conflicts() -> void:
	# 1. Sorting segments by X positions, to move from left to right
	sort_segments()

	for i in range(segments.size()):
		var current = segments[i]

		if i == 0:
			if current.position.x < 0:
				current.position.x = 0
			continue
			
		var previous = segments[i-1]
		var previous_end = previous.position.x + previous.size.x

		if current.position.x < previous_end:
			current.position.x = previous_end
			
	# Finally, update wrapper size and position
	_on_size_changed()


func add_segment(start_time: float, end_time: float) -> void:
	Debugger.debug("Adding segment from %.2f to %.2f" % [start_time, end_time])
	start_time = clamp(start_time, 0.0, total_duration)
	end_time = clamp(end_time, 0.0, total_duration)
	if end_time < start_time:
		var tmp = start_time
		start_time = end_time
		end_time = tmp
	var id = _last_segment_id
	
	var node = null
	if segments.size() != 0 and is_instance_valid(segments[0]):
		node = segments[0].duplicate()
	else:
		node = offset_controller.instantiate()
		segments.append(node) # final solution

	node.name = "Segment_%d" % id
	node.segment_id = id

	# check if node is valid
	add_child(node)

	import_initial_data(node_type, initial_path)

	node.connect("request_go_to", Callable(self, "_on_request_go_to"))
	node.connect("request_copy", Callable(self, "_on_request_copy"))
	node.connect("request_split", Callable(self, "split_segment"))
	node.connect("request_delete", Callable(self, "remove_segment"))
	
	node.connect("position_changed", Callable(self, "_on_position_changed")) # need to update wrapper size and conflicts
	node.connect("size_changed", Callable(self, "_on_size_changed")) # need to update wrapper as well
	
	node.connect("segment_size_changed", Callable(self, "_on_segment_size_changed"))

	segments.append(node)

	_last_segment_id += 1

	#_fix_all()

# Creates a segment with preset Cutoff settings
func add_segment_at(l_cutoff: float, r_cutoff: float) -> Control:
	var id = _last_segment_id
	var node = offset_controller.instantiate()

	node.name = "Segment_%d" % id
	node.segment_id = id
	add_child(node)
	
	# Loading data (thumbnails/waveform) into the new node
	# Important: import_initial_data should be able to work with a ready node,
	# or we can duplicate data from segments[0] if it's a duplicate, to avoid reloading from disk.
	# For simplicity, we'll keep your method:
	import_initial_data(node_type, initial_path) 

	# Apply cutoff settings
	node.left_cutoff = l_cutoff
	node.right_cutoff = r_cutoff

	node.connect("request_go_to", Callable(self, "_on_request_go_to"))
	node.connect("request_copy", Callable(self, "_on_request_copy"))
	node.connect("request_split", Callable(self, "split_segment"))
	node.connect("request_delete", Callable(self, "remove_segment"))
	node.connect("position_changed", Callable(self, "_on_position_changed"))
	node.connect("size_changed", Callable(self, "_on_size_changed"))

	node.apply_thumbnail_data(segments[0].thumbnails_container.get_children().map(func(x): return x.texture), total_duration) # Hack to pass textures, better to optimize
	node.update_range_rect()

	segments.append(node)
	_last_segment_id += 1
	return node


func remove_segment(node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	segments.erase(node)

"""
func split_segment(node, time_point: float) -> void:
	if time_point <= node.start_time or time_point >= node.end_time:
		return

	# Split
	node.end_time = time_point
	add_segment(time_point, node.end_time)
	#_fix_all()
"""
func split_segment(node: Control, global_pointer_x: float) -> void:
	# global_pointer_x - pointer position inside ControllerWrapper (local X)

	# if cutoff is inside of segment
	if global_pointer_x <= node.position.x or global_pointer_x >= (node.position.x + node.size.x):
		Debugger.warning("Split point is outside of the segment")
		return

	# position of splitting
	var local_split_pos = global_pointer_x - node.position.x

	# pixels to seconds
	var split_seconds_delta = local_split_pos / node.px_to_sec_ratio 

	var split_file_time = node.left_cutoff + split_seconds_delta

	var old_right_cutoff = node.right_cutoff

	# left segment ends on split point
	node.right_cutoff = node.total_duration - split_file_time
	node.update_range_rect()

	# new right segment starts on split point and goes to old right cutoff
	var new_node = add_segment_at(split_file_time, old_right_cutoff)
	new_node.position.x = global_pointer_x

	# Fixing potential misplacements
	_resolve_conflicts()

"""
func merge_segments(left_id: int, right_id: int) -> int:
	if not (segments.has(left_id) and segments.has(right_id)):
		return -1
	var left = segments[left_id]
	var right = segments[right_id]
	# Right ordering
	if left["start"] > right["start"]:
		var tmp = left_id
		left_id = right_id
		right_id = tmp
		left = segments[left_id]
		right = segments[right_id]
	var new_start = left["start"]
	var new_end = max(left["end"], right["end"])
	remove_segment(right_id)
	segments[left_id]["end"] = new_end
	emit_signal("segment_updated", left_id, new_start, new_end)
	#_fix_all() ## TODO: Change name and princple
	return left_id
"""


func merge_segments(node_a: Control, node_b: Control) -> void:
	# 1. Need to determine left and right segments
	var left_seg = node_a
	var right_seg = node_b

	if node_a.position.x > node_b.position.x:
		left_seg = node_b
		right_seg = node_a

	left_seg.right_cutoff = right_seg.right_cutoff

	# Updating visuals of left segment
	left_seg.update_range_rect()

	remove_segment(right_seg)

	_on_size_changed()


func _on_request_go_to(node, position: float) -> void:
	time_pointer.position.x = position

"""
func _on_request_copy(node) -> void:
	add_segment(node.start_time, node.end_time)
"""
func _on_request_copy(node) -> void:
	# create copy
	var new_node = add_segment_at(node.left_cutoff, node.right_cutoff)

	# Set it slightly to the right of the original to ensure _resolve_conflicts understands the order
	new_node.position.x = node.position.x + node.size.x + 1.0 

	_resolve_conflicts()


func _on_position_changed() -> void:

	var min_width := _get_minimal_width()
	self.custom_minimum_size.x = min_width
	self.size.x = self.custom_minimum_size.x

	## handle_conflicts()


func _on_size_changed():
	"""
	1. Get total size of all segments and gaps between them
	2. calculate new size of controller_wrapper - self.size.x
	3. update wrapper size
	4. update wrapper position
	"""
	var min_width := _get_minimal_width()
	self.custom_minimum_size.x = min_width
	self.size.x = self.custom_minimum_size.x

	#_fix_all()


func _get_minimal_width() -> float:
	var min_width := 0.0
	for segment in segments:
		min_width += segment.size.x + segment.global_offset - segment.left_cutoff - segment.right_cutoff
	return min_width


func _on_segment_size_changed(segment_id: int):
	var seg = segments.get(segment_id)
	if not seg:
		return
	
	var min_width := 0.0
	for child in segments:
		min_width += child.global_offset
		min_width += child.size.x

	self.size.x = min_width


func sort_segments() -> void:
	var sorted_segments = []
	var segment_positions = {}
	for seg in segments:
		segment_positions[seg.position.x] = seg
	
	# Sorting
	var keys = segment_positions.keys()
	keys.sort()
	for pos in keys:
		sorted_segments.append(segment_positions[pos])
	segments = sorted_segments


func prepare_export_timecodes() -> Array:
	var export_timecodes: Array = []
	sort_segments()
	for seg in segments:
		# Make sure, that segments are sorted by start_time on timeline
		export_timecodes.append({
			"from_time": seg.start_time,
			"to_time": seg.end_time
		})
	return export_timecodes
