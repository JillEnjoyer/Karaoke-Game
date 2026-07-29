#main_menu.gd
extends Control

@onready var media_player = $MediaPlayer

func _ready():
	media_player.highlight_preinit()


func _test_init_highlight():
	_test_add_highlight()
	## "main_menu_highlights_enabled": true
	## "main_menu_highlights": [] ## many paths where path = catalog_path + song_folder + "config.json"
	var result = PreferencesData.get_data("main_menu_highlights_enabled")
	if result:
		var highlights = PreferencesData.get_data("main_menu_highlights")
		if highlights and highlights.size() > 0:
			var random_index = randi() % highlights.size()
			var highlight_path = highlights[random_index]
			await get_tree().create_timer(2.0).timeout
			media_player.highlight_init(_temp_get_highlight(highlight_path), highlight_path, true)
			Debugger.debug("Highlight initialized with: " + highlight_path)
		else:
			Debugger.debug("No highlights found in preferences.")
	else:
		Debugger.debug("Main menu highlights are disabled in preferences.")

func _test_add_highlight():
	var test_song_path := "X:/Projects/Godot/Karaoke/Catalog/Grand Blue/Seishun Towa"
	var highlights = PreferencesData.get_data("main_menu_highlights")

	if test_song_path in highlights:
		Debugger.info("Highlight already exists in the list.")
		return
	
	highlights.append(test_song_path)
	PreferencesData.set_data("main_menu_highlights", highlights, true)


func _temp_get_highlight(song_path: String) -> Array:
	var config_path = song_path.path_join("config.json")
	if not FileAccess.file_exists(config_path):
		printerr("No Highlight available at: ", config_path)
		return []
	# Read and parse ONLY IF timer sucessfully ended
	var data = FileAccess.get_file_as_string(config_path)

	var parsed_data = JSON.parse_string(data)
	if parsed_data and parsed_data.has("highlights"):
		Debugger.error("Failed to parse JSON and/or highlights are missing: " + config_path)
		return parsed_data["highlights"]

	return []


func _on_catalog_btn_pressed() -> void:
	UIManager.cleanup_tree()
	if PreferencesData.get_data("style") == "2d":
		UIManager.show_ui("Catalog")
	else:
		UIManager.show_ui("Catalog3D")


func _on_editor_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("EditorScene")


func _on_settings_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("Settings")

## TODO: Change before release
func _on_exit_btn_pressed() -> void:
	UIManager.show_ui("TempDebugMenu")
	self.queue_free()
