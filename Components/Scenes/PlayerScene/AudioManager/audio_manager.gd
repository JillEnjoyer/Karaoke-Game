extends Node

signal last_audio_ended

#var audio_init = AudioPlayerInstance.new()

var is_playing: bool = false
var speed_multiplier: float = 1.0

var players := {}
var type := "" ## Acapella / Instrumental
# var mode := "" ## standart / highlight

var current_time := 0.0
#var delta_time := 0.0
var timer := 1.0


func init(song_path: String, data_dict: Dictionary, manager_type: String, playback_mode: String = "standard") -> void:
	self.type = manager_type
	Debugger.debug(str(data_dict))

	prepare_all_players(data_dict, song_path, playback_mode)


func update_timer(time: float) -> void:
	for player in players:
		players[player].update_timer(time)


func prepare_all_players(type_config: Dictionary, song_path: String, playback_mode: String) -> void:
	for version_name in type_config:
		var audio_controller = AudioController.new(self)
		audio_controller.name = version_name
		audio_controller.connect("audio_ended", Callable(self, "_on_audio_ended"))
		players[version_name] = audio_controller

		audio_controller.load_audio(type_config[version_name], version_name, type, song_path, playback_mode)


func set_pause_state(audio_lists: Array, paused: bool):
	for audio_list in audio_lists:
		for key in audio_list:
			if audio_list[key] is AudioStreamPlayer:
				audio_list[key].stream_paused = paused


func wipe_manager() -> void:
	for player in self.get_children():
		player.queue_free()
	players.clear()


func _on_audio_ended(controller_name: String) -> void:
	Debugger.debug("Audio ended received from controller: " + controller_name)
	players.erase(controller_name)
	if players.size() == 0:
		Debugger.debug("All audio controllers ended for type: " + type)
		emit_signal("last_audio_ended")


func pause() -> void:
	for player in players:
		players[player].pause()
func resume() -> void:
	for player in players:
		players[player].resume()
func start() -> void:
	for player in players:
		players[player].start()
func seek(to_time: float) -> void:
	for player in players:
		players[player].seek(to_time)


func sync_controllers(time: float) -> void:
	for player in players:
		players[player].seek(time)
