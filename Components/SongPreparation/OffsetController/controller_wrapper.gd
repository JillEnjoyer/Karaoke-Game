# ControllerWrapper
extends Control
## Controls a single media object's segments
## Calculates and stores total duration that is being sent to timeline
## Handles segment creation, deletion, splitting, merging
## Stores cutoffs and offsets for each segment to save for future user playback

var thumbnail_generator = ThumbnailGenerator.new()
var waveform_generator = WaveformGenerator.new()
var context_menu = ContextMenuManager.new()
var dot_drawer = ""

var ffmpeg_path = PreferencesData.getExtPath("ffmpeg")

@onready var offset_controller = UIManager.get_desired_node("offset_controller")

var timestamp = 5.0 # seconds per frame - can be changed by resize
var px_to_sec_ratio: float = (70.0 * 16.0 / 9.0) / timestamp # should be dinamic to timestamp change

var node_name := ""
var initial_path := ""
var node_type := ""
var total_duration := 1.0

var px_per_second := 1.0
var _last_segment_id := 0
var bind_threshold := 0.1

var segments := {}


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
	elif type == "subtitles":
		draw_dots()

## Onetime setup methods
func create_thumbnails(path: String):
	var data = thumbnail_generator.generate_thumbnails(path, timestamp)
	var textures = data.get("thumbnails", [])
	total_duration = data["metadata"].get("duration", 0.0)
	segments[0]["node"].apply_thumbnail_data(textures, total_duration)
func create_waveform(path: String):
	self.size.x = 100.0
	self.size.y = 70.0
	var texture = waveform_generator.load_waveform_image(path, ffmpeg_path, self.size.x, self.size.y, "black")
	segments[0]["node"].apply_thumbnail_data([texture], total_duration)
func draw_dots():
	Debugger.warning("Not implemented yet")


func add_segment(start_time: float, end_time: float) -> int:
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
		node = segments[0]["node"].duplicate()
	else:
		node = offset_controller.instantiate()
		segments[0] = {"start": 0.0, "end": total_duration, "node": node}

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

	segments[id] = {
		"segment_id": id,
		"node": node,
		"start": start_time,
		"end": end_time
	}

	_last_segment_id += 1

	_position_segment_node(id)
	emit_signal("segment_created", id, start_time, end_time, node)
	_fix_all()
	return id


func remove_segment(id: int) -> void:
	if not segments.has(id):
		return
	var node = segments[id]["node"]
	if is_instance_valid(node):
		node.queue_free()
	segments.erase(id)


func split_segment(id: int, time_point: float) -> int:
	if not segments.has(id):
		return -1
	var seg = segments[id]
	var s = seg["start"]
	var e = seg["end"]
	if time_point <= s or time_point >= e:
		return -1
	segments[id]["end"] = time_point
	#emit_signal("segment_updated", id, s, time_point)
	var new_id = add_segment(time_point, e)
	_fix_all()
	return new_id


func merge_segments(left_id: int, right_id: int) -> int:
	if not (segments.has(left_id) and segments.has(right_id)):
		return -1
	var left = segments[left_id]
	var right = segments[right_id]
	# Упорядочим
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
	_position_segment_node(left_id)
	_fix_all()
	return left_id


func update_segment(id: int, new_start: float, new_end: float) -> void:
	if not segments.has(id):
		return
	new_start = clamp(new_start, 0.0, total_duration)
	new_end = clamp(new_end, 0.0, total_duration)
	if new_end < new_start:
		var t = new_start
		new_start = new_end
		new_end = t
	segments[id]["start"] = new_start
	segments[id]["end"] = new_end
	emit_signal("segment_updated", id, new_start, new_end)
	_position_segment_node(id)
	_fix_all()


func get_segments_sorted() -> Array:
	var arr: Array = []
	for id in segments.keys():
		var seg = segments[id]
		arr.append({
			"id": id,
			"start": seg["start"],
			"end": seg["end"],
			"node": seg["node"]
		})
	arr.sort_custom(func(a, b): return a["start"] < b["start"])
	return arr


##______ Internal methods for metrics and positioning _____##
func _update_metrics():
	if total_duration <= 0.0:
		total_duration = 0.001
	px_per_second = size.x / total_duration if total_duration > 0.0 else 1.0


func time_to_px(t: float) -> float:
	return t * px_per_second
func px_to_time(px: float) -> float:
	return px / px_per_second


func _position_segment_node(id: int):
	var seg = segments[id]
	var node: Control = seg["node"]
	if not is_instance_valid(node):
		return
	var w = max(1.0, time_to_px(seg["end"] - seg["start"]))
	node.position.x = time_to_px(seg["start"])
	node.size.x = w
	# Высоту/стиль можно настроить
	node.size.y = 40


func _fix_all():
	if segments.size() <= 1:
		return

	# Delete negative/invalid segments
	for id in segments.keys():
		var seg = segments[id]
		if seg["end"] <= seg["start"]:
			remove_segment(id)
	# Sort and fix overlaps
	var sorted = get_segments_sorted()
	for i in range(sorted.size() - 1):
		var a = sorted[i]
		var b = sorted[i + 1]
		if a["end"] > b["start"]:
			# overlap detected
			var overlap = a["end"] - b["start"]
			var len_a = a["end"] - a["start"]
			var ratio = overlap / len_a if len_a > 0 else 1.0
			# Пример логики (можно скорректировать):
			if ratio < 0.7:
				# Сдвиг правого сегмента
				update_segment(b["id"], a["end"], max(a["end"], b["end"]))
			elif ratio < 0.95:
				# Смена мест
				var tmp_start = a["start"]
				var tmp_end = a["end"]
				update_segment(a["id"], b["start"], b["end"])
				update_segment(b["id"], tmp_start, tmp_end)
			else:
				# Fully covered — merging
				merge_segments(a["id"], b["id"])
				sorted = get_segments_sorted()
				break
	# Binding segments
	_bind_close_segments()
	for id in segments.keys():
		_position_segment_node(id)
	emit_signal("segments_changed")


func _bind_close_segments():
	var sorted = get_segments_sorted()
	for i in range(sorted.size() - 1):
		var a = sorted[i]
		var b = sorted[i + 1]
		var gap = b["start"] - a["end"]
		if gap > 0.0 and gap < bind_threshold:
			update_segment(b["id"], a["end"], b["end"])


func _on_request_go_to(segment_id: int) -> void:
	"""
	1. получить сегмент по ID
	2. получить время начала сегмента
	3. выставить
	4. WIP
	"""
	var seg = segments.get(segment_id)
	if not seg:
		return
	var start_time = seg["start"]
	# Set the playback position to the start of the segment
	emit_signal("go_to_position", start_time)


func _on_request_copy(segment_id: int) -> void:
	"""
	1. получить сегмент по ID
	2. дублировать сегмент
	3. выставить его позицию справа от оригинала
	"""


func _on_position_changed(segment_id: int, new_offset: float) -> void:
	"""
	1. Получить общий размер всех сегментов и промежутков между ними
	2. вычислить новый размер обертки controller_wrapper - self.size.x
	3. обновить позицию обертки
	"""
	Debugger.debug("Position changed for segment %d to %.2f" % [segment_id, new_offset])

	var min_width := _get_minimal_width()
	self.custom_minimum_size.x = min_width
	self.size.x = self.custom_minimum_size.x

	segments[segment_id]["node"].position.x = clampf(new_offset, 0.0, INF)
	_fix_all()


func _on_size_changed():
	"""
	1. Получить общий размер всех сегментов и промежутков между ними
	2. вычислить новый размер обертки controller_wrapper - self.size.x
	3. обновить размер обертки
	4. обновить позицию обертки
	"""
	var min_width := _get_minimal_width()
	self.custom_minimum_size.x = min_width
	self.size.x = self.custom_minimum_size.x

	_fix_all()


func _get_minimal_width() -> float:
	var min_width := 0.0
	for segment in segments.values():
		min_width += segment["node"].size.x + segment["node"].global_offset - segment["node"].left_cutoff - segment["node"].right_cutoff
	return min_width


func _on_segment_size_changed(segment_id: int):
	var seg = segments.get(segment_id)
	if not seg:
		return
	
	var min_width := 0.0
	for child in segments.values():
		min_width += child["node"].global_offset
		min_width += child["node"].size.x

	self.size.x = min_width
