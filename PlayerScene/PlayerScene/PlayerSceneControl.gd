extends Control

@onready var VideoRenderer = $VideoRenderer
@onready var AudioDecoder = $AudioDecoder
@onready var Voice_Channel_HBox = $PlayerSceneUi/Voice_Channel_HBox
@onready var slider_control = $PlayerSceneUi/TimeSlider

var video_link = ""
var instrumental_link = ""
var instrumental_list = {}
var acapella_list = {}
var subtitles_list = []
var character_list = {}


var video_position = 0.0
var instrumental_positions = {}
var acapella_positions = {}
var current_subtitle_line = 0


var instrumental_players = {}
var acapella_players = {}


var framerate = 1.0
var length = 1.0
var timer = 1.0
var time_passed = 0.0
var playback_speed = 1.0
var is_playing = false
var playtime = 0.0
var metadata_array = {}
var procent = 0.0

var debugging: bool = false

var song_counter = 0
var playlist: Dictionary

func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	print("Screen Size: ", screen_size)


func import_playlist(imported_playlist: Dictionary) -> void: # when module first startup
	# playlist dict holds songs like an array: playlist = {0: [franchise_name, song_name, performer_name, mode]}
	playlist = imported_playlist
	
	start_song()


# every new song in playlist calls it
func init(data: Array) -> void:
	var main_path = data[0] + "/" + data[1] + "/"
	var base_audio_path = main_path + "Audio/"
	var base_acapella_path = base_audio_path + data[2] + "/"
	var main_file = main_path + "Config.txt"
	var base_subtitle_path = main_path + "Subtitles/"
	var absolute_video_path = data[0] + "/" + data[1] + "/" + video_link
	
	if not FileAccess.file_exists(main_file):
		Debugger.error("PlayerSceneControl.gd", "init()", "Config file does not exist: " + str(main_file))
		return
	
	parse_config(main_file)
	
	VideoRenderer.load_video(absolute_video_path)
	AudioDecoder.load_instrumental(base_audio_path)
	AudioDecoder.load_acapella(base_acapella_path)
	
	#time_slider.connect("h_slider_value_changed_signal", Callable(self, "on_slider_value_changed"))
	start_timer_before_play()


func start_song() -> void:
	init(playlist[song_counter])
	song_counter += 1


func on_slider_value_changed(value: float) -> void:
	print("recieved value: " + str(value))
	print(length)
	seek((length/100.0)*value)


func parse_config(config_path: String) -> void:
	var parser = ConfigParser.new()
	var parsed_data = parser.get_parsed_data(config_path)
	
	video_link = parsed_data["video_link"]
	#instrumental_link = parsed_data["instrumental_link"]
	instrumental_list = parsed_data["instrumental_list"]
	acapella_list = parsed_data["acapella_list"]
	character_list = parsed_data["character_list"]
	subtitles_list = parsed_data["subtitles_list"]


func _process(delta: float) -> void:
	if is_playing:
		#time_slider.slider.value += (delta/length)*100.0
		time_passed += delta * playback_speed
		playtime += delta * playback_speed
		if time_passed >= timer:
			time_passed -= timer
			VideoRenderer.update_frame()


func seek(time: float) -> void:
	if Video:
		VideoRenderer.seek_video(time)
	for instrumental_player in instrumental_players.values():
		instrumental_player.seek(time)
	for player in acapella_players.values():
		player.seek(time)


func set_playback_speed(speed: float):
	playback_speed = speed
	#audio_node.pitch_scale = playback_speed


func get_current_subtitle_line(time: float) -> int:
	for i in range(subtitles_list.size()):
		var subtitle_time = float(subtitles_list[i].split(",")[0])
		if subtitle_time > time:
			return i - 1
	return subtitles_list.size() - 1


func show_pause_menu() -> void:
	if get_node("/root/ViewportBase/SubViewportContainer/SubViewport/PlayerScene").has_node("PauseMenu"):
		Debugger.info("PlayerSceneControl.gd", "show_pause_menu()", "Pause menu already exists, not spawning a new one.")
		return

	var pause_menu_instance = UIManager.show_ui("pause_menu_scene")
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	pause_all()


func pause_all() -> void:
	is_playing = false
	
	for instrumental_player in instrumental_players.values():
		instrumental_player.stream_paused = true
		instrumental_positions[instrumental_player] = instrumental_player.get_playback_position()
	
	for player in acapella_players.values():
		player.stream_paused = true
		acapella_positions[player] = player.get_playback_position()
	
	#current_subtitle_line = get_current_subtitle_line(instrumental_position)


func resume_all() -> void:
	is_playing = true

	for instrumental_player in instrumental_players.values():
		instrumental_player.seek(instrumental_positions[instrumental_player])
		instrumental_player.stream_paused = false

	for player in acapella_players.values():
		player.seek(acapella_positions[player])
		player.stream_paused = false


func start_all() -> void:
	is_playing = true
	
	for instrumental_player in acapella_players.values():
		instrumental_player.playing = true
	
	for player in acapella_players.values():
		player.playing = true


func _input(event: InputEvent) -> void:
	if not debugging and event.is_action_pressed("pause"):
		show_pause_menu()


func start_timer_before_play() -> void:
	var timer_instance = UIManager.show_ui("timer_scene")
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))


func _on_pause_menu_continue() -> void:
	Debugger.info("PlayerSceneControl.gd", "resume_all()", "Continue signal received, resuming playback.")
	start_timer_before_play()


func _on_timer_ready_to_start() -> void:
	Debugger.info("PlayerSceneControl.gd", "resume_all()", "Timer finished, starting playback.")
	start_all()
	#resume_all()
