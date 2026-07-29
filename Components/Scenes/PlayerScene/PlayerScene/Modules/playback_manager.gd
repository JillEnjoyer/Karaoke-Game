extends Node

signal song_completed

@onready var video_manager = $VideoManager
@onready var instrumental_manager = $InstrumentalManager
@onready var acapella_manager = $AcapellaManager
@onready var subtitle_manager = $SubtitleManager

var is_highlight_mode := false
var highlight_start := 0.0
var highlight_end := 0.0
var highlight_repeat := false

var is_playing = false
var is_started = false
var playtime: float = 0.0## - PreferencesData.get_data("countdown_time") ## We start with negative time to let buffers to preload content - Logical time
var length: float = 1000.0 ## Need to be changed to be sure that song will eventually end.

## Playback flags
var video_ended_flag: bool = false
var instrumental_ended_flag: bool = false
var acapella_ended_flag: bool = false
var subtitles_ended_flag: bool = true


func _ready() -> void:
	pass


func change_blur():
	video_manager.change_blur()


func init_managers(data: Dictionary, song_path: String, highlight_mode: bool = false) -> void:
	Debugger.debug("data: " + str(data))
	
	wipe_managers()

	video_manager.init(song_path, data.get("video_dict", {}))
	video_manager.connect("video_ended", Callable(self, "_handle_video_ended"))

	instrumental_manager.init(song_path, data.get("instrumental_dict", {}), "instrumental")
	instrumental_manager.connect("last_audio_ended", Callable(self, "_handle_instrumental_audio_ended"))

	acapella_manager.init(song_path, data.get("acapella_dict", {}), "acapella", highlight_mode)
	acapella_manager.connect("last_audio_ended", Callable(self, "_handle_acapella_audio_ended"))

	#subtitle_manager.init(song_path, data["subtitle_path"], "karaoke", result["character_dict"])
	subtitle_manager.init(data.get("subtitle_data", []), "karaoke", data.get("character_dict", []))
	subtitle_manager.connect("subtitles_ended", Callable(self, "_handle_subtitles_ended"))

	if highlight_mode:
		is_highlight_mode = true

		highlight_start = data.get("highlight_start", 0.0)
		highlight_end = data.get("highlight_end", 1.0)
		highlight_repeat = data.get("highlight_repeat", false)

		var voice_channel_jumpers = data.get("highlight_extras", [])
		instrumental_manager.set_extras(voice_channel_jumpers)
		acapella_manager.set_extras(voice_channel_jumpers)

		await get_tree().process_frame
		playtime = highlight_start
		length = highlight_end - highlight_start + 1.0
		#seek(playtime)
		start_all(playtime)
	else:
		start_timer_before_play()

	Debugger.debug("managers initialized, highlight mode: " + str(highlight_mode) + ", highlight start: " + str(highlight_start) + ", highlight end: " + str(highlight_end) + ", highlight repeat: " + str(highlight_repeat))


func wipe_managers() -> void:
	pause_all()

	video_manager.wipe_manager()
	instrumental_manager.wipe_manager()
	acapella_manager.wipe_manager()
	subtitle_manager.wipe_manager()

	await get_tree().process_frame


func _process(delta: float) -> void:
	#Debugger.debug("Playtime: " + str(playtime))
	if is_playing:
		playtime += delta

		video_manager.update_timer(playtime)
		instrumental_manager.update_timer(playtime)
		acapella_manager.update_timer(playtime)
		subtitle_manager.update_timer(playtime)

		if is_highlight_mode:
			if playtime >= highlight_end:
				if highlight_repeat:
					playtime = highlight_start
					seek(playtime)
				else:
					pause_all()
		else:
			if playtime > length:
				pause_all()
				Debugger.warning("Playtime exceeds length: " + str(playtime) + " > " + str(length))


func control_audio_channels() -> void:
	instrumental_manager.control_audio_channels()
	acapella_manager.control_audio_channels()


func seek(time: float) -> void:
	Debugger.debug("Seeking to time: " + str(time))
	video_manager.seek(time)
	instrumental_manager.seek(time)
	acapella_manager.seek(time)
	#subtitle_manager.seek(time)


func pause_all() -> void:
	is_playing = false
	video_manager.pause() # But not important - if counter stops, video stops as well
	instrumental_manager.pause()
	acapella_manager.pause()
	subtitle_manager.pause()
func resume_all() -> void:
	is_playing = true
	video_manager.resume() # But not important
	instrumental_manager.resume()
	acapella_manager.resume()
	subtitle_manager.resume()
func start_all(time: float = 0.0) -> void:
	is_playing = true
	video_manager.start(time) # But not important
	instrumental_manager.start(time)
	acapella_manager.start(time)
	subtitle_manager.resume()


func _handle_video_ended() -> void:
	Debugger.info("VideoManager sent signal: Video ended")
	video_ended_flag = true
	is_song_ended()
func _handle_instrumental_audio_ended() -> void:
	Debugger.info("AudioManager sent signal: Last audio ended")
	instrumental_ended_flag = true
	is_song_ended()
func _handle_acapella_audio_ended() -> void:
	Debugger.info("AudioManager sent signal: Last audio ended")
	acapella_ended_flag = true
	is_song_ended()
func _handle_subtitles_ended():
	Debugger.info("SubtitleManager sent signal: Subtitles ended")
	subtitles_ended_flag = true
	is_song_ended()

func is_song_ended() -> void:
	if video_ended_flag and instrumental_ended_flag and acapella_ended_flag and subtitles_ended_flag:
		pause_all()
		is_playing = false
		emit_signal("song_completed")


func start_timer_before_play() -> void:
	var timer_instance = UIManager.show_ui("TimerScene")
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))
func _on_timer_ready_to_start() -> void:
	Debugger.info("Timer finished, starting playback.")
	if not is_started:
		start_all()
		is_started = true
	else:
		resume_all()

	Debugger.info("Current playtime: " + str(playtime))


func _exit_tree() -> void:
	wipe_managers()
