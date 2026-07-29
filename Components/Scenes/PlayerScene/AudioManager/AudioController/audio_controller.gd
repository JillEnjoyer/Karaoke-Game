extends Node
class_name AudioController

signal audio_ended(controller_name)

var manager = null
var audio_player: AudioStreamPlayer = null

var physical_time := 0.0 ## Time that defines real length of audio file and its seek
var logical_time := 0.0 ## Time that defines length of configurational playback

var normalized_segments: Array = []
var current_segment: Dictionary = {}
var current_index := 0

var voice_channel_extras := []
var last_enabled_state := true
var extras_initialized := false
var highlight_extra_index := 0

#var voice_channel_timesteps := []


func _init(manager_node) -> void:
	manager = manager_node


func load_audio(config: Dictionary, file_name: String, file_type: String, file_path: String, highlight: bool) -> void:
	var player = AudioPlayerInstance.get_audio_player(file_path.path_join(config["path"]))
	player.name = file_name
	player.connect("finished", Callable(self, "_on_audio_finished"))

	var max_physical_time = player.stream.get_length()
	normalized_segments = SegmentNormalizer.build_segment_map(config.get("segments", []), {file_name: max_physical_time})
	current_segment = normalized_segments[0]
	Debugger.debug("Normalized segments for " + file_name + ": " + str(normalized_segments))

	UIManager.new_child(player, manager)
	audio_player = player

	## divide channel control block for acapella and instrumental
	if file_type == "acapella" and not highlight:
		pass#create_voice_channel_control(file_name)
		## TODO: FIX


func set_extras(highlight_extras: Array) -> void:
	voice_channel_extras = highlight_extras


func create_voice_channel_control(player_name: String) -> void:
	var instance = UIManager.show_ui("VoiceChannelControl", "PlayerScene/UI/SoundMixer/Panel/Voice_Channel_HBox")
	instance.get_node("Ch_NameLbl").text = player_name
	instance.connect("value_changed_signal", Callable(self, "on_value_changed"))
func on_value_changed(value) -> void:
	Debugger.debug("value changed for " + self.name + ": " + str(value))
	audio_player.volume_db = value


## Playback
func update_timer(time: float) -> void:
	var delta = time - logical_time
	physical_time += delta
	logical_time = time

	handle_extras()

	# Проверяем, не вышли ли мы за пределы текущего логического сегмента
	if logical_time > current_segment["logical_end"]:
		if current_index + 1 < normalized_segments.size():
			current_index += 1
			current_segment = normalized_segments[current_index]
			
			# Высчитываем физическое время с учетом смещения внутри нового сегмента
			var offset = logical_time - current_segment["logical_start"]
			physical_time = current_segment["physical_start"] + offset
			
			Debugger.debug("Entering next segment: " + str(current_segment) + ", physical_time: " + str(physical_time))


func handle_extras() -> void:
	if voice_channel_extras.is_empty():
		return

	if not extras_initialized:
		prepare_player_for_extras()
		extras_initialized = true

	for i in range(voice_channel_extras.size()):
		if logical_time >= voice_channel_extras[i].get("logical_start", 0.0):
			highlight_extra_index = i
		else:
			break
	
	if highlight_extra_index != -1:
		var current_extra_config = voice_channel_extras[highlight_extra_index]
		if current_extra_config.has(audio_player.name):
			var should_be_enabled = current_extra_config[audio_player.name]
			if should_be_enabled != last_enabled_state:
				Debugger.debug("Setting track " + audio_player.name + " to " + ("enabled" if should_be_enabled else "disabled") + " at logical time: " + str(logical_time))
				set_track_mute(should_be_enabled)
				last_enabled_state = should_be_enabled


func prepare_player_for_extras() -> void:
	audio_player.volume_db = -80.0

func logical_to_physical(time_logical: float) -> float:
	for segment in normalized_segments:
		if time_logical >= segment["logical_start"] and time_logical <= segment["logical_end"]:
			var offset = time_logical - segment["logical_start"]
			return segment["physical_start"] + offset
	return physical_time
func physical_to_logical(time_physical: float) -> float:
	for segment in normalized_segments:
		if time_physical >= segment["physical_start"] and time_physical <= segment["physical_end"]:
			var offset = time_physical - segment["physical_start"]
			return segment["logical_start"] + offset
	return logical_time


func set_track_mute(is_enabled: bool) -> void:
	var target_db = 0.0 if is_enabled else -80.0
	var tween = create_tween()
	audio_player.volume_db = target_db
	#tween.tween_property(audio_player, "volume_db", target_db, 0.3)


## Control
func pause() -> void:
	#physical_time = on_time
	audio_player.stream_paused = true
func resume() -> void:
	audio_player.seek(physical_time)
	audio_player.stream_paused = false
func start(time: float = 0.0) -> void:
	audio_player.playing = true
	audio_player.stream_paused = true
	seek(time)


func seek(to_time_logical: float) -> void:
	logical_time = to_time_logical
	
	for i in range(normalized_segments.size()):
		var seg = normalized_segments[i]
		if to_time_logical >= seg["logical_start"] and to_time_logical <= seg["logical_end"]:
			current_index = i
			current_segment = seg
			break

	if current_segment["id"] != "EMPTY":
		var offset = to_time_logical - current_segment["logical_start"]
		physical_time = current_segment["physical_start"] + offset
		
		audio_player.stream_paused = false
		audio_player.seek(physical_time)
	
	# Принудительно обновляем экстры при прыжке по таймлайну
	last_enabled_state = !last_enabled_state 
	handle_extras()


func _on_audio_finished() -> void:
	Debugger.debug("Audio finished for controller: " + str(self.name))
	emit_signal("audio_ended", self.name)
