extends Control

signal song_completed

#@onready var control_manager = $ControlManager
@onready var playback_manager = $PlaybackManager
@onready var song_data_loader = $SongDataLoader
@onready var playlist_manager = $PlaylistManager

var editor_mode := false

var playlist = []
var input_data := {
	"album_path": "",
	"chosen_index": 0
}

var song_data := {}
var song_path := ""
var config_file

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
		
		if song.size() > 0 and karaoke_init(song):
			await self.song_completed
		else:
			Debugger.debug("Skipping invalid song: " + str(song))

		playlist.remove_at(index)

	return_to_catalog()


func karaoke_init(playlist_song: Dictionary = {}) -> bool:
	song_data = playlist_song
	is_highlight_mode = false
	
	var result: Dictionary = song_data_loader.player_scene_partial_init(playlist_song)
	if not result:
		return false

	playback_manager.init_managers(result, result["song_path"])

	return true


func highlight_init(input_highlight_data: Array = [], imported_song_path: String = "", is_random: bool = false) -> void:
	playback_manager.pause_all()
	is_highlight_mode = true
	song_path = imported_song_path

	var highlight_data = song_data_loader.highlight_partial_init(song_path, input_highlight_data, is_random)
	if highlight_data.is_empty():
		Debugger.warning("No highlights found for: " + song_path)
		return
	
	playback_manager.init_managers(highlight_data, song_path, is_highlight_mode)

	var version = highlight_data.get("version", "")
	config_file = highlight_data.get("config_file", "")


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

	var pause_menu_instance = UIManager.show_ui("PauseMenu")
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	pause_menu_instance.connect("Restart", Callable(self, "_on_pause_menu_restart"))
	pause_menu_instance.connect("MainMenu", Callable(self, "_on_pause_menu_main_menu"))
	playback_manager.pause_all()


func _input(event: InputEvent) -> void:
	if is_highlight_mode:
		return
	
	if event.is_action_pressed("pause"):
		show_pause_menu()
	## other inputs to expand functionality


func _on_pause_menu_continue() -> void:
	Debugger.info("Continue signal received, resuming playback.")
	playback_manager.start_timer_before_play()


func _on_pause_menu_restart() -> void:
	Debugger.info("Restart signal received, restarting song.")
	playback_manager.wipe_managers()
	karaoke_init(song_data)


func _on_pause_menu_main_menu() -> void:
	Debugger.info("MainMenu signal received, returning to main menu.")
	return_to_catalog()


func return_to_catalog() -> void:
	await get_tree().create_timer(5).timeout
	UIManager.cleanup_tree()
	var catalog = UIManager.show_ui("Catalog")
	#catalog.return_catalog_position(input_data["album_path"], input_data["chosen_index"])
	catalog.call_deferred("return_catalog_position", [input_data["album_path"], input_data["chosen_index"]])
