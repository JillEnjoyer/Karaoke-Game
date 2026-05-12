extends Node
class_name AudioController

signal audio_ended(controller_name)

var manager = null

var audio_player: AudioStreamPlayer = null
#var path := ""

var physical_time := 0.0 ## Time that defines real length of audio file and its seek
var logical_time := 0.0 ## Time that defines length of configurational playback

var normalized_jumpers: Array = []
var current_segment: Dictionary = {}
var current_index := 1

var voice_channel_extras := []
#var voice_channel_extras_current_segment: Dictionary = {}
#var voice_channel_extras_current_index := 0
var last_enabled_state := true

var extras_initialized := false
var highlight_extra_index := 0
var voice_channel_timesteps := []

## Init
func _init(manager_node) -> void:
	manager = manager_node


func load_audio(config: Dictionary, file_name: String, file_type: String, file_path: String, highlight: bool) -> void:
	var player = AudioPlayerInstance.get_audio_player(file_path.path_join(config["path"]))
	player.name = file_name
	player.connect("finished", Callable(self, "_on_audio_finished"))

	physical_time = player.stream.get_length()
	normalized_jumpers = JumperNormalizer.build_jumper_map(config["jumpers"], {"file_name": physical_time})
	current_segment = normalized_jumpers[0]
	Debugger.debug("Normalized jumpers for " + file_name + ": " + str(normalized_jumpers))

	UIManager.new_child(player, manager)

	audio_player = player

	## divide channel control block for acapella and instrumental
	if file_type == "acapella" and not highlight:
		create_voice_channel_control(file_name)


func set_extras(highlight_extras: Array) -> void:
	voice_channel_extras = highlight_extras


func create_voice_channel_control(player_name: String) -> void:
	var instance = UIManager.show_ui("VoiceChannelControl", "PlayerScene/UI/SoundMixer/Panel/Voice_Channel_HBox") #"MediaPlayer/ControlManager/SoundMixer/Panel/Voice_Channel_HBox"
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

	## we need to jump on normalized jumpers when our logical time exceeds one of them. Need to find right on checking all the jumpers
	#current_segment = normalized_jumpers[current_index]
	if logical_time >= current_segment["logical_start"] and logical_time <= current_segment["logical_end"]:
		## its our jumper
		if current_segment["id"] == "EMPTY":
			return
	elif logical_time > current_segment["logical_end"]:
		if current_index + 1 < normalized_jumpers.size():
			current_index += 1

			current_segment = normalized_jumpers[current_index]
			physical_time = current_segment["physical_start"] + (logical_time - current_segment["logical_start"])
			Debugger.debug("Jumping to next segment: " + str(current_segment) + ", logical_time: " + str(logical_time) + ", physical_time: " + str(physical_time))
			
			#seek(physical_time)
			#Debugger.debug("jump to: " + str(physical_time))
			return


func handle_extras() -> void:
	if voice_channel_extras.is_empty():
		return

	if not extras_initialized:
		prepare_player_for_extras()
		extras_initialized = true

	# 1. Finding actual segment of a config for current logical_time
	#highlight_extra_index = -1
	for i in range(voice_channel_extras.size()):
		if logical_time >= voice_channel_extras[i].get("logical_start", 0.0):
			highlight_extra_index = i
		else:
			break
	
	# 2. If suitable segment found
	if highlight_extra_index != -1:
		var current_extra_config = voice_channel_extras[highlight_extra_index]
		
		# Is there our channel name
		if current_extra_config.has(audio_player.name):
			var should_be_enabled = current_extra_config[audio_player.name]
			
			# 3. Change if state changed
			#Debugger.debug("should_be_enabled: " + str("enabled" if should_be_enabled else "disabled") + ", last_enabled_state: " + str("enabled" if last_enabled_state else "disabled"))
			if should_be_enabled != last_enabled_state:
				Debugger.debug("Setting track " + audio_player.name + " to " + ("enabled" if should_be_enabled else "disabled") + " at logical time: " + str(logical_time))
				set_track_mute(should_be_enabled)
				last_enabled_state = should_be_enabled

func prepare_player_for_extras() -> void:
	audio_player.volume_db = -80.0

func logical_to_physical(time_logical: float) -> float:
	for segment in normalized_jumpers:
		if time_logical >= segment["logical_start"] and time_logical <= segment["logical_end"]:
			var offset = time_logical - segment["logical_start"]
			return segment["physical_start"] + offset
	return physical_time
func physical_to_logical(time_physical: float) -> float:
	for segment in normalized_jumpers:
		if time_physical >= segment["physical_start"] and time_physical <= segment["physical_end"]:
			var offset = time_physical - segment["physical_start"]
			return segment["logical_start"] + offset
	return logical_time


func set_track_mute(is_enabled: bool) -> void:
	var target_db = 0.0 if is_enabled else -80.0
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", target_db, 0.3)


## Control
func pause() -> void:
	#physical_time = on_time
	audio_player.stream_paused = true
func resume() -> void:
	audio_player.seek(physical_time)
	audio_player.stream_paused = false
func start(time: float = 0.0) -> void:
	#audio_player.seek(normalized_jumpers[1]["physical_start"])
	audio_player.playing = true
	audio_player.stream_paused = true
	seek(time)
	#audio_player.seek(normalized_jumpers[1]["physical_start"])
	Debugger.debug("audio controller: "+ str(self.name) + 
	"\nseek to the time: " + str(normalized_jumpers[1]["physical_start"]))

func seek(to_time_logical: float) -> void:
	logical_time = to_time_logical
	for i in range(normalized_jumpers.size()):
		var seg = normalized_jumpers[i]
		if to_time_logical >= seg["logical_start"] and to_time_logical <= seg["logical_end"]:
			current_index = i
			current_segment = seg
			break

	if current_segment["id"] != "EMPTY":
		var offset = to_time_logical - current_segment["logical_start"]
		physical_time = current_segment["physical_start"] + offset
		audio_player.stream_paused = false
		audio_player.seek(physical_time)
	
	last_enabled_state = !last_enabled_state 
	logical_time = to_time_logical
	handle_extras()

	audio_player.stream_paused = false


func _on_audio_finished() -> void:
	Debugger.debug("Audio finished for controller: " + str(self.name))
	emit_signal("audio_ended", self.name)
