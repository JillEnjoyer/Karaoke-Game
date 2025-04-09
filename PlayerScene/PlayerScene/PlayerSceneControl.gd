extends Control

@onready var VideoRenderer = $VideoRenderer
@onready var AudioDecoder = $AudioDecoder
@onready var Voice_Channel_HBox = $PlayerSceneUi/Voice_Channel_HBox
#@onready var slider_control = $PlayerSceneUi/TimeSlider

var debugging = false
var playlist = {}
var song_counter = 1

var video_list = {}
var instrumental_list = {}
var acapella_list = {}
var subtitles_list = {}
var character_list = []

var is_playing = false
var playtime = 0.0
var length = 1.0

var main_path
var config_file


func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	print("Screen Size: ", screen_size)
	


func import_playlist(imported_playlist: Dictionary) -> void:
	playlist = imported_playlist
	start_song()


func start_song() -> void:
	print(playlist)
	init(playlist[str(song_counter)])
	song_counter += 1


func init(data: Dictionary) -> void:
	main_path = data["path"]
	config_file = main_path + "/Config.json"
	
	if not FileAccess.file_exists(config_file):
		Debugger.error("PlayerSceneControl.gd", "init()", "Config file does not exist: " + str(config_file))
		return
	parse_config(config_file, data["video"], data["instrumental"], data["acapella"])
	
	VideoRenderer.init(video_list)
	VideoRenderer.connect("video_ended", Callable(self, "_handle_video_ended"))
	
	AudioDecoder.init(instrumental_list, "instrumental")
	AudioDecoder.init(acapella_list, "acapella")
	AudioDecoder.connect("last_audio_ended", Callable(self, "_handle_audio_ended"))
	
	# Subtitle loading is here
	
	start_timer_before_play()


func parse_config(config_path: String, desired_video: String, desired_instrumental: String, desired_acapella: String) -> void:
	var parser = ConfigParser.new()
	var parsed_data = parser.get_parsed_data(config_path, desired_video, desired_instrumental, desired_acapella)
	
	Debugger.debug("PlayerSceneControl.gd", "parse_config()", str(parsed_data))
	
	video_list = parsed_data["video_dict"]
	instrumental_list = parsed_data["instrumental_dict"]
	acapella_list = parsed_data["acapella_dict"]
	character_list = parsed_data["character_list"]
	subtitles_list = parsed_data["subtitle_dict"]
	
	
	for video in video_list:
		video_list[video]["path"] = str(main_path) + "/Video/" + video_list[video]["path"]
	
	for instrumental in instrumental_list:
		for file in instrumental_list[instrumental]:
			instrumental_list[instrumental][file]["path"] = str(main_path) + "/Audio/Instrumental/" + instrumental + "/" + instrumental_list[instrumental][file]["path"]
	
	for acapella in acapella_list:
		for file in acapella_list[acapella]:
			acapella_list[acapella][file]["path"] = str(main_path) + "/Audio/Instrumental/" + acapella + "/" + acapella_list[acapella][file]["path"]

	#for subtitle in subtitles_list:
		#var subtitle_id = str(subtitle["id"])
		#subtitle_paths[subtitle_id] = base_subtitle_path + subtitle_id + ".srt"


func _process(delta: float) -> void:
	if is_playing:
		playtime += delta
		if playtime > length:
			pause_all()
			Debugger.warning("PlayerSceneControl.gd", "_process()", "Playtime exceeds length: " + str(playtime) + " > " + str(length))


func seek(time: float) -> void:
	#var accessible_time = SubtitleProcessor.seek_to_closest_line(time) # = time - 0.25 secs
	#VideoRenderer.seek_video(accessible_time)
	#AudioDecoder.seek_to(accessible_time)
	pass


func get_current_subtitle_line(time: float) -> int:
	for i in range(subtitles_list.size()):
		var subtitle_time = float(subtitles_list[i].split(",")[0])
		if subtitle_time > time:
			return i - 1
	return subtitles_list.size() - 1


func show_pause_menu() -> void:
	
	if UIManager.default_parent.has_node("PauseMenu"):
		Debugger.info("PlayerSceneControl.gd", "show_pause_menu()", "Pause menu already exists, not spawning a new one.")
		return

	var pause_menu_instance = UIManager.show_ui("pause_menu_scene")
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	pause_all()


func pause_all() -> void:
	is_playing = false
	#VideoRenderer.pause()
	#AudioDecoder.pause_all()
	#SubtitleProcessor.pause()
	pass


func resume_all() -> void:
	is_playing = true
	#VideoRenderer.resume()
	#AudioDecoder.resume_all()
	#SubtitleProcessor.resume()
	pass


func _input(event: InputEvent) -> void:
	if not debugging and event.is_action_pressed("pause"):
		show_pause_menu()


func start_timer_before_play() -> void:
	var timer_instance = UIManager.show_ui("timer_scene")
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))


func on_slider_value_changed(value: float) -> void:
	print("recieved value: " + str(value))
	seek((length / 100.0) * value)


func _on_pause_menu_continue() -> void:
	Debugger.info("PlayerSceneControl.gd", "resume_all()", "Continue signal received, resuming playback.")
	start_timer_before_play()


func _on_timer_ready_to_start() -> void:
	Debugger.info("PlayerSceneControl.gd", "resume_all()", "Timer finished, starting playback.")
	resume_all()

func _handle_video_ended() -> void:
	Debugger.info("PlayerSceneControl.gd", "_handle_video_ended()", "VideoRenderer sent signal: Video ended")
