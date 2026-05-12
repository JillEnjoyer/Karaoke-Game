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

var normalized_jumpers := []
var current_jumper_index := 0

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
	# Getting delta
	time_delta += clamp((new_logical_time - logical_time), 0.0, frametime)
	logical_time = new_logical_time

	mutex.lock()
	if buffer.is_empty():
		mutex.unlock()
		return false
	
	#var frame_timestamp = buffer[0]["timestamp"]
	#var epsilon = frametime * 1.0 

	var should_show = time_delta >= frametime#logical_time >= (frame_timestamp - epsilon)
	if should_show:
		time_delta -= frametime

		# Correcting
		var drift = logical_time - buffer[0]["timestamp"]
		if abs(drift) > frametime * 2:
			Debugger.debug("Drift detected, correcting delta...")
			time_delta = frametime # Show frame immediately
	mutex.unlock()

	return should_show

## Video part init
##
## TODO: Need to also be ready to import video urls from Youtube
func _init(song_path: String = "", video_config: Dictionary = {}) -> void:
	Engine.get_main_loop().process_frame.connect(_on_engine_frame)

	if video_config == {} or song_path == "":
		return
	#"""
	var media_resources = {}
	if video_config.has("videos"): media_resources.merge(video_config["videos"])
	if video_config.has("images"): media_resources.merge(video_config["images"])

	for res_name in media_resources:
		var res_data = media_resources[res_name]
		var res_path = song_path.path_join(res_data["path"])
		
		var is_image = res_path.get_extension().to_lower() in ["jpg", "jpeg", "png", "webp"]
		if res_data.get("type") == "image": is_image = true

		video_controllers[res_name] = VideoController.new(self)
		video_controllers[res_name].name = res_name
		
		if is_image:
			video_controllers[res_name].load_as_image(res_path)
		else:
			video_controllers[res_name].load_video(res_path)

	if video_config.has("jumpers"):
		var video_lengths = {}
		for c_name in video_controllers:
			video_lengths[c_name] = video_controllers[c_name].length
		normalized_jumpers = JumperNormalizer.build_jumper_map(video_config["jumpers"], video_lengths)
	#"""
	"""
	for video_name in video_config:
		if not video_name == "jumpers":
			var video_path = song_path.path_join(video_config[video_name]["path"])

			video_controllers[video_name] = VideoController.new(self)
			video_controllers[video_name].name = video_name
			video_controllers[video_name].load_video(video_path)
		#else:
		#	normalized_jumpers = JumperNormalizer.build_jumper_map(video_config["jumpers"], video_controllers[video_name].length)

	for video_name in video_config:
		if video_name == "jumpers":
			var video_lengths = {}
			for controller_video_name in video_controllers:
				video_lengths[controller_video_name] = video_controllers[controller_video_name].length

			normalized_jumpers = JumperNormalizer.build_jumper_map(video_config["jumpers"], video_lengths)
			Debugger.debug("frame_buffer jumpers:" + str(normalized_jumpers))
	"""
	start_thread()


func _on_engine_frame() -> void:
	_frame_ready = true


"""
func switch_to_new_video():
	current_jumper_index += 1
	if current_jumper_index >= normalized_jumpers.size():
		Debugger.warning("No more jumpers left, end of video sequence.")
		return

	current_video_name = normalized_jumpers[current_jumper_index]["id"]
	var delta = normalized_jumpers[current_jumper_index]["logical_start"] - logical_time
	physical_time = normalized_jumpers[current_jumper_index]["physical_start"] + delta

	seek(physical_time)
"""

func start_thread() -> void:
	active = true
	should_terminate = false
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
		if not active or should_terminate:
			OS.delay_msec(10)
			continue

		while not _frame_ready and not should_terminate:
			OS.delay_msec(5)
		_frame_ready = false

		if is_instance_valid(self):
			if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
				fill_buffer_ring()
			else:
				fill_buffer_pop_append()


func fill_buffer_ring() -> void:
	var frames_in_buffer = (last_filled_step - next_step + buffer_size) % buffer_size
	if frames_in_buffer < buffer_frame_amount:
		var target_time = logical_time + max_delay
		# Find target_time segment
		var segment = null
		for s in normalized_jumpers:
			if target_time >= s["logical_start"] and target_time < s["logical_end"]:
				segment = s
				break
		if segment == null:
			Debugger.warning("No jumper segment found for time: " + str(target_time))
			OS.delay_msec(10)
			return

		var phys_time = segment["physical_start"] + (target_time - segment["logical_start"])

		# Toggle other video
		if current_jumper_index != segment["jumper_index"]:
			current_jumper_index = segment["jumper_index"]
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
	var local_logical_time: float
	var current_size: int
	var last_timestamp: float = -1.0

	mutex.lock()
	local_logical_time = logical_time
	current_size = buffer.size()
	if current_size > 0:
		last_timestamp = buffer[-1]["timestamp"]

	if current_size >= buffer_frame_amount:
		mutex.unlock()
		OS.delay_msec(5)
		return
	mutex.unlock()

	var target_time: float
	if last_timestamp < 0:
		target_time = local_logical_time
	else:
		target_time = last_timestamp + frametime

	var segment = null
	for s in normalized_jumpers:
		if target_time >= s["logical_start"] and target_time < s["logical_end"]:
			segment = s
			break
			
	if segment == null or segment["id"] == "EMPTY":
		OS.delay_msec(10)
		return

	if current_jumper_index != segment["jumper_index"]:
		current_jumper_index = segment["jumper_index"]
		current_video_name = segment["id"]
		## It is important to update frametime after switching video
		import_current_video_frametime() 
		seek(physical_to_logical(segment["physical_start"]))
		return

	var frame = video_controllers[current_video_name].get_next_frame()
	if frame:
		set_next_frame(frame, target_time)


func logical_to_physical(time_logical: float) -> float:
	for segment in normalized_jumpers:
		if time_logical >= segment["logical_start"] and time_logical <= segment["logical_end"]:
			var offset = time_logical - segment["logical_start"]
			return segment["physical_start"] + offset
	return physical_time
func physical_to_logical(time_physical: float) -> float:
	for segment in normalized_jumpers:
		if segment["id"] == "EMPTY":
			continue
		if time_physical >= segment["physical_start"] and time_physical <= segment["physical_end"]:
			var offset = time_physical - segment["physical_start"]
			return segment["logical_start"] + offset
	return logical_time


func import_current_video_frametime() -> void:
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
	if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
		buffer[next_step] = frame
		next_step = (next_step + 1) % buffer_size
		last_filled_step = (last_filled_step + 1) % buffer_size
	else:
		var frame_entry = {
			"image": frame,
			"timestamp": target_t
		}
		buffer.append(frame_entry)
	mutex.unlock()


func seek(l_time: float = 0.0) -> void:
	mutex.lock() 
	if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
		next_step = 0
		last_filled_step = -1
	else:
		buffer.clear()
		
	logical_time = l_time
	time_delta = 0.0

	var target_phys_time = 0.0
	for i in range(normalized_jumpers.size()):
		var seg = normalized_jumpers[i]
		if l_time >= seg["logical_start"] and l_time < seg["logical_end"]:
			current_jumper_index = i
			current_video_name = seg["id"]
			import_current_video_frametime()
			if seg["id"] != "EMPTY":
				target_phys_time = seg["physical_start"] + (l_time - seg["logical_start"])
			break
		else:
			Debugger.warning("No jumper segment found for logical time: " + str(l_time))

	physical_time = target_phys_time
	
	if current_video_name != "EMPTY" and current_video_name != "":
		if video_controllers.has(current_video_name):
			var initial_frame = video_controllers[current_video_name].seek(target_phys_time)
			if initial_frame:
				if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
					pass
				else:
					buffer.append({"image": initial_frame, "timestamp": l_time})
		
	mutex.unlock()


func _exit_tree() -> void:
	kill_thread()
	for video_name in video_controllers:
		video_controllers[video_name].queue_free()
	video_controllers.clear()
