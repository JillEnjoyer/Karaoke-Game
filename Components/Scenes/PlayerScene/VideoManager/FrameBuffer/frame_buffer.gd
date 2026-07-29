extends Node
class_name FrameBuffer

signal video_ended

var mutex := Mutex.new()

enum BUFFER_OPTIMIZATION_MODE {
	RING_BUFFER,
	POP_APPEND_BUFFER
}

var mode := BUFFER_OPTIMIZATION_MODE.POP_APPEND_BUFFER

var video_controllers := {}
var current_video_name := ""
var frametime := 1.0
var time_delta := 0.0
var buffer := []

var physical_time := 0.0
var logical_time := 0.0

var normalized_segments := []
var current_segment_index := 0

var thread := Thread.new()
var active := true
var should_terminate := false
var _frame_ready: bool = false

var max_delay := 0.025 ## up to 25ms

## buffer_filling_V1 == RingBuffer
var buffer_size := 12 # size can be changed later
var next_step := 0 # Next buffer index to return
var last_filled_step := 0 # Last filled buffer index
var buffer_frame_amount := 6 ## Goal for buffer filling - changable

## buffer_filling_V2 == BasicPopAppendBuffer

func _start() -> void:
	if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
		buffer_size = 12
	else:
		buffer_size = 0
	buffer.resize(buffer_size)

## _process subfunction
func update_timer(new_logical_time: float) -> bool:
	# ИСПРАВЛЕНИЕ ДРИФТА: Если разница слишком велика (смена песни), сбрасываем локальное время
	if abs(new_logical_time - logical_time) > 1.0:
		mutex.lock()
		logical_time = new_logical_time
		time_delta = 0.0
		buffer.clear()
		mutex.unlock()
		return false

	time_delta += clamp((new_logical_time - logical_time), 0.0, frametime)
	logical_time = new_logical_time

	mutex.lock()
	if buffer.is_empty():
		mutex.unlock()
		return false
	
	var should_show = time_delta >= frametime
	if should_show:
		time_delta -= frametime
		# Коррекция дрифта только для маленьких расхождений 
		var drift = logical_time - buffer[0]["timestamp"]
		if abs(drift) > frametime * 2:
			time_delta = frametime 
	mutex.unlock()

	#Debugger.debug()
	return should_show

## Video part init
##
## TODO: Need to also be ready to import video urls from Youtube
func _init(song_path: String = "", video_config: Dictionary = {}) -> void:
	Engine.get_main_loop().process_frame.connect(_on_engine_frame)

	if video_config == {} or song_path == "":
		return

	var media_resources = {}
	if video_config.has("videos"): media_resources.merge(video_config["videos"])
	if video_config.has("images"): media_resources.merge(video_config["images"])

	for res_name in media_resources:
		var res_data = media_resources[res_name]
		var res_path = song_path.path_join(res_data["path"])
		
		var is_image = res_path.get_extension().to_lower() in ["jpg", "jpeg", "png", "webp"]
		if res_data.get("type") == "image": is_image = true

		var controller = VideoController.new(self)
		controller.name = res_name
		video_controllers[res_name] = controller
		
		if is_image:
			controller.load_as_image(res_path)
		else:
			controller.load_video(res_path)

	if video_config.has("segments"):
		var video_lengths = {}
		for c_name in video_controllers:
			video_lengths[c_name] = video_controllers[c_name].length
		# ВАЖНО: убедитесь, что SegmentNormalizer возвращает массив [cite: 18, 20]
		normalized_segments = SegmentNormalizer.build_segment_map(video_config.get("segments", []), video_lengths)

	if not normalized_segments.is_empty():
		start_thread()


func _on_engine_frame() -> void:
	_frame_ready = true


func start_thread() -> void:
	should_terminate = false
	active = true
	if not thread.is_alive():
		thread.start(Callable(self, "_async_fill_buffer"))
func stop_thread() -> void:
	active = false
func kill_thread() -> void:
	should_terminate = true
	active = false
	if thread.is_alive():
		thread.wait_to_finish()


func _async_fill_buffer() -> void:
	while not should_terminate:
		if not active:
			OS.delay_msec(10)
			continue

		while not _frame_ready and not should_terminate:
			OS.delay_msec(5)
		_frame_ready = false

		if is_instance_valid(self):
			fill_buffer_pop_append()


func fill_buffer_ring() -> void:
	var frames_in_buffer = (last_filled_step - next_step + buffer_size) % buffer_size
	if frames_in_buffer < buffer_frame_amount:
		var target_time = logical_time + max_delay
		# Find target_time segment
		var segment = null
		for s in normalized_segments:
			if target_time >= s["logical_start"] and target_time < s["logical_end"]:
				segment = s
				break
		if segment == null:
			Debugger.warning("No segment found for time: " + str(target_time))
			OS.delay_msec(10)
			return

		var phys_time = segment["physical_start"] + (target_time - segment["logical_start"])

		# Toggle other video
		if current_segment_index != segment["segment_index"]:
			current_segment_index = segment["segment_index"]
			current_video_name = segment["id"]
			seek(phys_time)
			return

		# get frame by phys_time
		var frame = video_controllers[current_video_name].get_frame(phys_time)
		if frame:
			buffer[(last_filled_step + 1) % buffer_size] = frame
			last_filled_step = (last_filled_step + 1) % buffer_size
		else:
			Debugger.warning("Failed to get frame at " + str(phys_time))
	else:
		OS.delay_msec(int(max_delay * 1000 * 5))

func fill_buffer_pop_append() -> void:
	mutex.lock()
	if normalized_segments.is_empty() or buffer.size() >= buffer_frame_amount:
		mutex.unlock()
		OS.delay_msec(5)
		return
	
	var last_ts = buffer[-1]["timestamp"] if not buffer.is_empty() else logical_time
	mutex.unlock()

	var target_time = last_ts + frametime
	var segment = null
	for s in normalized_segments:
		if target_time >= s["logical_start"] and target_time < s["logical_end"]:
			segment = s
			break

	# Если сегмент сменился, нужно сделать seek в контроллере
	if segment and current_segment_index != segment["segment_index"]:
		mutex.lock()
		current_segment_index = segment["segment_index"]
		current_video_name = segment["id"]
		import_current_video_frametime()
		var phys = segment["physical_start"]
		video_controllers[current_video_name].seek(phys)
		mutex.unlock()
		
	if segment == null or segment["id"] == "EMPTY":
		return
	
	var frame: Image
	if video_controllers.has(current_video_name):
		frame = video_controllers[current_video_name].get_next_frame()
	if frame:
		set_next_frame(frame, target_time)


func logical_to_physical(time_logical: float) -> float:
	for segment in normalized_segments:
		if time_logical >= segment["logical_start"] and time_logical <= segment["logical_end"]:
			var offset = time_logical - segment["logical_start"]
			return segment["physical_start"] + offset
	return physical_time
func physical_to_logical(time_physical: float) -> float:
	for segment in normalized_segments:
		if segment["id"] == "EMPTY":
			continue
		if time_physical >= segment["physical_start"] and time_physical <= segment["physical_end"]:
			var offset = time_physical - segment["physical_start"]
			return segment["logical_start"] + offset
	return logical_time


func import_current_video_frametime() -> void:
	if video_controllers.has(current_video_name):
		frametime = video_controllers[current_video_name].frametime


func get_next_frame() -> Image:
	mutex.lock()
	if buffer.is_empty():
		mutex.unlock()
		return null

	while buffer.size() > 1 and logical_time >= buffer[1]["timestamp"]:
		buffer.pop_front()
			
	var frame_data = buffer.pop_front()
	var img = frame_data["image"]
	mutex.unlock()
	return img


func set_next_frame(frame: Image, target_t: float) -> void:
	mutex.lock()
	buffer.append({"image": frame, "timestamp": target_t})
	mutex.unlock()


func seek(l_time: float = 0.0) -> void:
	mutex.lock() 
	buffer.clear()
	logical_time = l_time
	time_delta = 0.0

	# ИСПРАВЛЕНИЕ: Проверка на пустые сегменты перед поиском 
	if normalized_segments.is_empty():
		mutex.unlock()
		return

	var found_segment = false
	for i in range(normalized_segments.size()):
		var seg = normalized_segments[i]
		if l_time >= seg["logical_start"] and l_time <= seg["logical_end"]:
			current_segment_index = i
			current_video_name = seg["id"]
			import_current_video_frametime()
			if seg["id"] != "EMPTY":
				physical_time = seg["physical_start"] + (l_time - seg["logical_start"])
			found_segment = true
			break

	if found_segment and video_controllers.has(current_video_name):#if found_segment and current_video_name != "EMPTY" and video_controllers.has(current_video_name):
		var initial_frame = video_controllers[current_video_name].seek(physical_time)
		if initial_frame:
			buffer.append({"image": initial_frame, "timestamp": l_time})
		
	mutex.unlock()


func _exit_tree() -> void:
	kill_thread()
	mutex.lock()
	for video_name in video_controllers:
		if is_instance_valid(video_controllers[video_name]):
			video_controllers[video_name].queue_free()
	video_controllers.clear()
	mutex.unlock()
