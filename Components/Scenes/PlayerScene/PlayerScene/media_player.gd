extends Control

signal song_completed

@onready var video_manager = $VideoManager
@onready var instrumental_manager = $InstrumentalManager
@onready var acapella_manager = $AcapellaManager
@onready var subtitle_manager = $SubtitleManager
#@onready var sound_mixer = $UI

var editor_mode := false
var started := false

var playlist = []

var video_dict := {}
var instrumental_dict := {}
var acapella_dict := {}
var subtitle_path := ""
var character_dict := []

var is_playing = false
var playtime: float = 0.0 - PreferencesData.get_data("countdown_time")
var length: float = 100.0

var input_data := {
	"album_path": "",
	"chosen_index": 0
}
var song_path := ""
#var config_file

var video_ended_flag: bool = false
var instrumental_ended_flag: bool = false
var acapella_ended_flag: bool = false
var subtitles_ended_flag: bool = true


var is_highlight_mode := false
var highlight_start := 0.0
var highlight_end := 0.0
var highlight_repeat := false


func _ready() -> void:
	pass


func import_playlist(imported_data: Dictionary, imported_playlist: Array) -> void:
	input_data = imported_data
	playlist = imported_playlist
	start_song()


func start_song() -> void:
	var index := 0
	while playlist.size() > 0:
		## index = randi_range(0, playlist.size() - 1) # Can be randomized later
		var song = playlist[index]
		
		if song.size() > 0 and player_scene_init(song):
			await self.song_completed
		else:
			Debugger.debug("Skipping invalid song: " + str(song))

		playlist.remove_at(index)

	return_to_catalog()

## true - everything is correct, false - something went wrong
func player_scene_init(playlist_song: Dictionary = {}) -> bool:
	is_highlight_mode = false
	song_path = playlist_song["song_path"]
	var config_file = song_path.path_join("Configs").path_join(playlist_song["version"] + ".json")
	subtitle_path = song_path.path_join("Subtitles/[PREPARED]").path_join(playlist_song["version"] + ".json")
	
	if not FileAccess.file_exists(config_file):
		Debugger.error("Config file does not exist: " + str(config_file))
		return false
	
	parse_config(config_file)
	
	video_manager.init(song_path, video_dict)
	video_manager.connect("video_ended", Callable(self, "_handle_video_ended"))
	
	instrumental_manager.init(song_path, instrumental_dict, "instrumental")
	instrumental_manager.connect("last_audio_ended", Callable(self, "_handle_instrumental_audio_ended"))
	Debugger.debug("instrumental loaded: " + str(instrumental_dict))
	
	acapella_manager.init(song_path, acapella_dict, "acapella")
	acapella_manager.connect("last_audio_ended", Callable(self, "_handle_acapella_audio_ended"))
	Debugger.debug("acapella loaded: " + str(acapella_dict))

	#subtitle_manager.init(song_path, subtitle_path, "karaoke", character_dict)
	#subtitle_manager.connect("subtitles_ended", Callable(self, "_handle_subtitles_ended"))
	Debugger.debug("Subtitle file loaded: " + subtitle_path)

	start_timer_before_play()

	return true

func highlight_init(input_highlight_data: Array = [], imported_song_path: String = "") -> void:
	pause_all()
	is_highlight_mode = true
	song_path = imported_song_path
	
	## might be random if random flag is set
	var data = input_highlight_data[0]
	Debugger.debug("input_highlight_data: " + str(input_highlight_data) + "\n\n data: " + str(data) + "\n\n song_path: " + song_path)

	if input_highlight_data.is_empty():
		Debugger.warning("No highlights found for: " + song_path)
		return

	# Use the first highlight available
	var highlight_config = input_highlight_data[0]
	
	var version = highlight_config.get("version", "")
	highlight_start = highlight_config.get("logical_start", 0.0)
	highlight_end = highlight_config.get("logical_end", 1.0)
	highlight_repeat = highlight_config.get("repeat", false)
	
	var config_file = song_path.path_join("Configs").path_join(version + ".json")
	
	if not FileAccess.file_exists(config_file):
		Debugger.error("Config file does not exist: " + str(config_file))
		return
	
	parse_config(config_file)
	
	video_manager.init(song_path, video_dict)
	instrumental_manager.init(song_path, instrumental_dict, "instrumental")
	acapella_manager.init(song_path, acapella_dict, "acapella", "highlight")
	
	playtime = highlight_start
	
	await get_tree().process_frame # wait a frame to ensure everything is ready
	#await get_tree().create_timer(5).timeout # small delay to ensure smoothness
	seek(playtime)
	start_all()


func parse_config(config_path: String) -> void:
	var parser = ConfigParser.new()
	var parsed_data: Dictionary = parser.get_parsed_data(config_path)
	Debugger.debug(str(parsed_data))
	
	video_dict = parsed_data["video"]
	instrumental_dict = parsed_data["instrumental"]
	acapella_dict = parsed_data["acapella"]
	character_dict = parsed_data["characters"]


func wipe_managers() -> void:
	video_manager.wipe_manager()
	instrumental_manager.wipe_manager()
	acapella_manager.wipe_manager()
	#subtitle_manager.wipe_manager()


func _process(delta: float) -> void:
	if is_playing:
		playtime += delta

		video_manager.update_timer(playtime)
		instrumental_manager.update_timer(playtime)
		acapella_manager.update_timer(playtime)
		#subtitle_manager.update_timer(playtime)

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


func is_song_ended() -> void:
	if video_ended_flag and instrumental_ended_flag and acapella_ended_flag and subtitles_ended_flag:
		pause_all()
		started = false
		emit_signal("song_completed")


func seek(time: float) -> void:
	video_manager.seek(time)
	instrumental_manager.seek(time)
	acapella_manager.seek(time)

"""
func get_current_subtitle_line(time: float) -> int:
	for i in range(subtitles_list.size()):
		var subtitle_time = float(subtitles_list[i].split(",")[0])
		if subtitle_time > time:
			return i - 1
	return subtitles_list.size() - 1
"""

func show_pause_menu() -> void:
	if UIManager.default_parent.has_node("PauseMenu"):
		Debugger.info("Pause menu already exists, not spawning a new one.")
		return

	var pause_menu_instance = UIManager.show_ui("pause_menu")
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	pause_all()


func pause_all() -> void:
	is_playing = false
	#video_manager.pause() # Not needed anymore - if counter stops, video stops as well
	instrumental_manager.pause()
	acapella_manager.pause()
	#subtitle_manager.pause()
func resume_all() -> void:
	is_playing = true
	#video_manager.resume() # Not needed anymore
	instrumental_manager.resume()
	acapella_manager.resume()
	#subtitle_manager.resume()
func start_all() -> void:
	is_playing = true
	#video_manager.start() # Not needed anymore
	instrumental_manager.start()
	acapella_manager.start()
	#subtitle_manager.resume()


func _input(event: InputEvent) -> void:
	if is_highlight_mode:
		return
	
	if event.is_action_pressed("pause"):
		show_pause_menu()
	## other inputs to expand functionality


func _on_pause_menu_continue() -> void:
	Debugger.info("Continue signal received, resuming playback.")
	start_timer_before_play()
func start_timer_before_play() -> void:
	var timer_instance = UIManager.show_ui("timer_scene")
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))
func _on_timer_ready_to_start() -> void:
	Debugger.info("Timer finished, starting playback.")
	#resume_all()
	if not started:
		start_all()
		started = true
	else:
		resume_all()


func _handle_video_ended() -> void:
	Debugger.info("VideoRenderer sent signal: Video ended")
	video_ended_flag = true
func _handle_instrumental_audio_ended() -> void:
	Debugger.info("AudioDecoder sent signal: Last audio ended")
	instrumental_ended_flag = true
func _handle_acapella_audio_ended() -> void:
	Debugger.info("AudioDecoder sent signal: Last audio ended")
	acapella_ended_flag = true
func _handle_subtitles_ended():
	Debugger.info("VideoRenderer sent signal: Video ended")
	subtitles_ended_flag = true


func return_to_catalog() -> void:
	await get_tree().create_timer(5).timeout
	UIManager.cleanup_tree()
	var catalog = UIManager.show_ui("catalog")
	#catalog.return_catalog_position(input_data["album_path"], input_data["chosen_index"])
	catalog.call_deferred("return_catalog_position", [input_data["album_path"], input_data["chosen_index"]])
