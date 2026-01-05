extends Node
class_name FrameBuffer
## FrameBuffer controls what video should give frames rn - it gets main video config and fetch frames based on config
##
## VideoManager asks for frames in buffer, for seeking and for other commands from here, passing them to video controller classes.

signal video_ended

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
	var time_shift = new_logical_time - logical_time
	time_delta += time_shift
	physical_time += time_shift
	logical_time = new_logical_time

	if time_delta >= frametime:
		time_delta -= frametime
		return true
	return false

## Video part init
##
## TODO: Need to also be ready to import video urls from Youtube
func _init(song_path: String = "", video_config: Dictionary = {}) -> void:
	if video_config == {} or song_path == "":
		return

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
	
	start_thread()
	#seek(normalized_jumpers[current_jumper_index]["physical_start"])

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
	if thread.is_alive():
		thread.wait_to_finish()


func _async_fill_buffer() -> void:
	while not should_terminate:
		if not active:
			OS.delay_msec(10)
			continue

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
	if buffer.size() < buffer_frame_amount:
		var target_time = logical_time + max_delay
		# Find a segment for target time
		var segment = null
		for s in normalized_jumpers:
			if target_time >= s["logical_start"] and target_time < s["logical_end"]:
				segment = s
				break
		if segment == null:
			Debugger.warning("No jumper segment found for time: " + str(target_time))
			OS.delay_msec(10)
			return
		
		if segment["id"] == "EMPTY":
			OS.delay_msec(10)
			return

		var phys_time = segment["physical_start"] + (target_time - segment["logical_start"])

		# Change video, if needed
		if current_jumper_index != segment["jumper_index"]:
			current_jumper_index = segment["jumper_index"]
			current_video_name = segment["id"]

			#Debugger.debug("Index changed: " + str(current_jumper_index))

			import_current_video_frametime()
			seek(physical_to_logical(phys_time))
			return

		# get_frame for phys_time
		var frame = video_controllers[current_video_name].get_next_frame()
		if frame:
			buffer.append(frame)
			#Debugger.debug("Frame Added to buffer at time " + str(target_time) + "/ " + str(phys_time) + "/ buffer size: " + str(buffer.size()))
		else:
			Debugger.warning("Failed to get frame at " + str(phys_time))
	else:
		OS.delay_msec(int(max_delay * 1000 * 2))


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
	var next_frame
	if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
		var frames_in_buffer = (last_filled_step - next_step + buffer_size) % buffer_size ## (-1 - 0 + 12) % 12 - gives 11 instead of 0
		if frames_in_buffer == 0:
			Debugger.warning("Frame was requested before buffering ended")
			return null
		next_frame = buffer[next_step]
		next_step = (next_step + 1) % buffer_size
	else:
		if not buffer.is_empty():
			next_frame = buffer.pop_front()
			#Debugger.debug("Image from buffer was retrieved at " + str(logical_time))

	return next_frame


func _seek(p_time: float = 0.0) -> void:
	video_controllers[current_video_name].seek(p_time)
func seek(l_time: float = 0.0) -> void:
	if mode == BUFFER_OPTIMIZATION_MODE.RING_BUFFER:
		next_step = 0
		last_filled_step = -1
	else:
		buffer.clear()
	_seek(logical_to_physical(l_time))


func _exit_tree() -> void:
	kill_thread()
	for video_name in video_controllers:
		video_controllers[video_name].queue_free()
	video_controllers.clear()
