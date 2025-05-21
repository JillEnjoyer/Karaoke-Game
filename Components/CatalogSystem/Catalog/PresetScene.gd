extends Control

var text_load = TextureLoader.new()

@onready var song_ui = $SongUI
@onready var playlist_ui = $PlaylistUI

@onready var NameLbl = $SongNameLbl
@onready var SongIcon = $SongIcon

@onready var SongModeCheckBox = $SongUI/ModeCheckBox
@onready var VideoCheckBox = $SongUI/VideoCheckBox
@onready var InstrumentalCheckBox = $SongUI/InstrumentalCheckBox
@onready var AcapellaCheckBox = $SongUI/AcapellaCheckBox

@onready var PlaylistModeCheckBox = $PlaylistUI/ModeCheckBox
@onready var RepeatCheckBox = $PlaylistUI/RepeatCheckBox
@onready var ShuffleCheckBox = $PlaylistUI/ShuffleCheckBox
@onready var PlaylistCheckBox = $PlaylistUI/PlaylistCheckBox

var BasePath = "Catalog"
var FolderName = ""
var Path = ""

var VideoData = {}
var InstrumentalData = {}
var AcapellaData = {}
var PlaylistItems = []

var type = ""
var current_playlist = {}

var local_path = ""
var choosen_video = ""
var choosen_instrumental = ""
var choosen_acapella = ""


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
		Debugger.error("PresetScene.gd", "setup_mode()", "Not recognised preset scene type: " + str(type))


func CollectNames(Base: String, Folder: String):
	BasePath = Base
	FolderName = Folder
	Path = BasePath + "/" + FolderName
	Debugger.debug("PresetScene.gd", "CollectNames()", "FrPath = " + BasePath)
	Debugger.debug("PresetScene.gd", "CollectNames()", "SnName = " + Folder)
	
	Init()


func Init():
	NameLbl.text = FolderName
	SongIcon.texture = text_load.load_texture(BasePath + "/" + FolderName + "/" + "Icon.png")
	
	ScanFolder()
	
	SongModeCheckBox.text = "Standart"
	AcapellaCheckBox.clear()
	
	if type == "single":
		for instrumental_folder in InstrumentalData.keys():
			InstrumentalCheckBox.add_item(instrumental_folder)
		for acapella_folder in AcapellaData.keys():
			AcapellaCheckBox.add_item(acapella_folder)
		for video_file in VideoData.keys():
			VideoCheckBox.add_item(video_file)
		
	elif type == "playlist":
		for playlist_name in PlaylistItems.keys():
			PlaylistCheckBox.add_item(playlist_name)


func ScanFolder():
	Path = BasePath + "/" + FolderName
	AcapellaData = {}
	InstrumentalData = {}
	
	
	if type == "single":
		AcapellaData = scan_audio_folder(Path + "/Audio/Acapella")
		InstrumentalData = scan_audio_folder(Path + "/Audio/Instrumental")
		VideoData = scan_video_folder(Path + "/Video")
		
	elif type == "playlist":
		var dir = DirAccess.open(Path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			PlaylistItems = []
			
			while file_name != "":
				if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
					var basename = file_name.get_basename()
					PlaylistItems.append(basename)
				
				file_name = dir.get_next()
			
			dir.list_dir_end()
			_populate_playlist_checkbox(PlaylistItems)
		else:
			Debugger.debug("PresetScene.gd", "ScanFolder()", "Failed to open folder: " + Path)
	
	Debugger.info("PresetScene.gd", "ScanFolder()", "Path for scanning = " + Path)
	Debugger.debug("PresetScene.gd", "ScanFolder()", "Acapella: " + str(AcapellaData))
	Debugger.debug("PresetScene.gd", "ScanFolder()", "Instrumental: " + str(InstrumentalData))


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
		Debugger.debug("PresetScene.gd", "_scan_audio_folder()", "Failed to open folder: " + folder_path)
	
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
		Debugger.debug("PresetScene.gd", "scan_video_files()", "Failed to open folder: " + folder_path)
	
	return result


func _populate_playlist_checkbox(items: Array) -> void:
	PlaylistModeCheckBox.clear()
	for idx in range(items.size()):
		PlaylistModeCheckBox.add_item(items[idx], idx)


func pack_to_playlist():
	var playlist = {}
	
	playlist["1"] = {
		"path": local_path,
		"video": choosen_video,
		"instrumental": choosen_instrumental,
		"acapella": choosen_acapella
	}
	return playlist


func start_karaoke(playlist: Dictionary) -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("player_scene").import_playlist(playlist)


func _on_back_btn_pressed() -> void:
	self.queue_free()


func _on_start_btn_pressed() -> void:
	local_path = Path
	choosen_video = VideoCheckBox.get_item_text(VideoCheckBox.selected)
	choosen_instrumental = InstrumentalCheckBox.get_item_text(InstrumentalCheckBox.selected)
	choosen_acapella = AcapellaCheckBox.get_item_text(AcapellaCheckBox.selected)
	
	if type == "single":
		current_playlist = pack_to_playlist()
		Debugger.debug("PresetScene.gd", "_on_start_btn_pressed()", "current_playlist: " + str(current_playlist))
	start_karaoke(current_playlist)
