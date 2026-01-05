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

## Init
func _init(manager_node) -> void:
	manager = manager_node


func load_audio(config: Dictionary, file_name: String, file_type: String, file_path: String, mode: String) -> void:
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
	if file_type == "acapella" and mode != "highlight":
		create_voice_channel_control(file_name)


func create_voice_channel_control(player_name: String) -> void:
	var instance = UIManager.show_ui("voice_channel_control", "PlayerScene/UI/SoundMixer/Panel/Voice_Channel_HBox")
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
			
			seek(physical_time)
			Debugger.debug("jump to: " + str(physical_time))
			return


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

## Control
func pause() -> void:
	#physical_time = on_time
	audio_player.stream_paused = true
func resume() -> void:
	audio_player.seek(physical_time)
	audio_player.stream_paused = false
func start() -> void:
	audio_player.playing = true
	audio_player.seek(normalized_jumpers[1]["physical_start"])
	audio_player.stream_paused = false
	Debugger.debug("audio controller: "+ str(self.name) + 
	"\nseek to the time: " + str(normalized_jumpers[1]["physical_start"]))
func seek(to_time_physical: float) -> void:
	audio_player.seek(to_time_physical)
	Debugger.debug("audio controller: "+ str(self.name) + "seek time: " + str(to_time_physical))


func _on_audio_finished() -> void:
	Debugger.debug("Audio finished for controller: " + str(self.name))
	emit_signal("audio_ended", self.name)
