extends Control

@onready var animation_player := $AnimationPlayer

@onready var song_ui := $Panel/SongUI
@onready var playlist_ui := $Panel/PlaylistUI

@onready var name_lbl := $Panel/SongUI/SongNameLbl
@onready var song_icon := $Panel/SongUI/SongIcon
@onready var song_mode_checkbox := $Panel/SongUI/VBoxContainer/GameModeHbox/ModeCheckBox
#@onready var instrumental_checkbox := $Panel/SongUI/VBoxContainer/InstrumentalHbox/InstrumentalCheckBox
@onready var acapella_checkbox := $Panel/SongUI/VBoxContainer/AcapellaHbox/AcapellaCheckBox

@onready var playlist_mode_checkbox := $Panel/PlaylistUI/VBoxContainer/ModeHbox/ModeCheckBox
@onready var repeat_checkbox := $Panel/PlaylistUI/VBoxContainer/RepeatHbox/RepeatCheckBox
@onready var shuffle_checkbox := $Panel/PlaylistUI/VBoxContainer/ShuffleHbox/ShuffleCheckBox
@onready var playlist_check_box := $Panel/PlaylistUI/VBoxContainer/PlaylistHbox/PlaylistCheckBox

var base_path := "Catalog"
var folder_name := ""
var song_path := ""
var card_index := 0

var acapella_data := {}
var playlist_items := []

var type := ""


func _ready() -> void:
	pass


func setup_mode(ui_type):
	type = ui_type
	if ui_type == "single":
		song_ui.visible = true
		playlist_ui.visible = false
	elif ui_type == "playlist":
		song_ui.visible = false
		playlist_ui.visible = true
	else:
		Debugger.error("Not recognised preset scene type: " + str(type))
		push_error(ui_type + "is not recognized!")


func collect_names(base: String, folder: String, choosen_index: int):
	base_path = base
	folder_name = folder
	song_path = base_path + "/" + folder_name
	card_index = choosen_index
	Debugger.debug("FrPath = " + base_path)
	Debugger.debug("SnName = " + folder)
	
	init()
	animation_player.play("show_panel")


func init():
	name_lbl.text = folder_name
	song_icon.texture = TextureLoader.load_texture(base_path + "/" + folder_name + "/" + "Icon.png")
	
	scan_folder()
	
	song_mode_checkbox.text = "Standart"
	acapella_checkbox.clear()
	
	if type == "single":
		for acapella_folder in acapella_data.keys():
			acapella_checkbox.add_item(acapella_folder)
		
	elif type == "playlist":
		for playlist_name in playlist_items:
			playlist_check_box.add_item(playlist_name)


func scan_folder():
	song_path = base_path + "/" + folder_name
	acapella_data = {}
	
	
	if type == "single":
		acapella_data = scan_audio_folder(song_path + "/Audio/Acapella")
		
	elif type == "playlist":
		var dir = DirAccess.open(song_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			playlist_items = []
			
			while file_name != "":
				if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
					var basename = file_name.get_basename()
					playlist_items.append(basename)
				
				file_name = dir.get_next()
			
			dir.list_dir_end()
			_populate_playlist_checkbox(playlist_items)
		else:
			Debugger.debug("Failed to open folder: " + song_path)
	
	Debugger.info("Path for scanning = " + song_path)
	Debugger.debug("Acapella: " + str(acapella_data))


func scan_audio_folder(folder_path: String) -> Dictionary:
	var result = {}
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var item_name = dir.get_next()
		
		while item_name != "":
			if dir.current_is_dir() and item_name != "." and item_name != "..":
				result[item_name] = true  # true indicates it's a folder
			item_name = dir.get_next()
		dir.list_dir_end()
	else:
		Debugger.debug("Failed to open folder: " + folder_path)
	
	return result


func scan_video_folder(folder_path: String, extensions: Array = [".mp4", ".webm"]) -> Dictionary:
	var result = {}
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var item_name = dir.get_next()
		
		while item_name != "":
			if not dir.current_is_dir():
				var ext = item_name.get_extension().to_lower()
				if extensions.has("." + ext):
					result[item_name.get_basename()] = {
						"full_path": folder_path.path_join(item_name),
						"extension": ext
					}
			item_name = dir.get_next()
		dir.list_dir_end()
	else:
		Debugger.debug("Failed to open folder: " + folder_path)
	
	return result


func _populate_playlist_checkbox(items: Array) -> void:
	playlist_mode_checkbox.clear()
	for idx in range(items.size()):
		playlist_mode_checkbox.add_item(items[idx], idx)


func pack_to_playlist(choosen_acapella: String = "") -> Array[Dictionary]:
	var playlist: Array[Dictionary] = []
	
	playlist.append({
		"song_path": song_path,
		"version": choosen_acapella
	})
	return playlist


func start_karaoke(playlist: Array) -> void:
	UIManager.cleanup_tree()
	var player_scene = UIManager.show_ui("player_scene")
	var input_data := {
		"album_path": null,
		"chosen_index": null
	}
	input_data["album_path"] = base_path
	input_data["chosen_index"] = card_index

	player_scene.import_playlist(input_data, playlist)


func _on_back_btn_pressed() -> void:
	animation_player.play_backwards("show_panel")
	await animation_player.animation_finished
	self.queue_free()


func _on_start_btn_pressed() -> void:
	var choosen_acapella = acapella_checkbox.get_item_text(acapella_checkbox.selected)
	var current_playlist := []

	if type == "single":
		current_playlist = pack_to_playlist(choosen_acapella)
		Debugger.debug("current_playlist: " + str(current_playlist))
	start_karaoke(current_playlist)
