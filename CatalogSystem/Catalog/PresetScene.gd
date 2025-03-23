extends Control

var text_load = texture_loader.new()

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

var EndPath = ""
var BasePath = "Catalog"  # Базовая папка Catalog
var FolderName = ""
var Acapella = ""
var FolderData = {}

var type = ""
var playlists = {}  # Словарь для хранения плейлистов: { "PlaylistName": "path/to/playlist.json" }


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
		#load_playlists()  # Загружаем плейлисты при инициализации режима "playlist"
	else:
		Debugger.error("PresetScene.gd", "setup_mode()", "Not recognised preset scene type: " + str(type))


# тут мы получаем: (полную ссылку до названия конечной папки) и (имя конечной папки)
#
func CollectNames(Base: String, Folder: String):
	BasePath = Base
	FolderName = Folder
	Debugger.debug("PresetScene.gd", "CollectNames()", "FrPath = " + BasePath)
	Debugger.debug("PresetScene.gd", "CollectNames()", "SnName = " + Folder)
	
	Init()


"""
Нужно:
1. по типу инициализировать данные
"""
func Init():
	ScanFolder()
	if type == "single":
		SongModeCheckBox.text = "Standart"
		AcapellaCheckBox.clear()

		for folder_name in FolderData.keys():
			AcapellaCheckBox.add_item(folder_name)
		
		Debugger.debug("PresetScene.gd", "Init()", EndPath + "/" + BasePath + "/" + FolderName + "/" + Acapella)
		
		NameLbl.text = FolderName
		SongIcon.texture = text_load.load_texture(BasePath + "/" + FolderName + "/" + "Icon.png")

		if AcapellaCheckBox.get_item_count() > 0:
			var selected_acapella = AcapellaCheckBox.get_item_text(0)
			var config = load_song_config(BasePath + "/" + FolderName + "/" + selected_acapella)
			if config:
				var acapella_tracks = config.get("Audiotracks", {}).get("Acapella", [])
				for track in acapella_tracks:
					if track.get("version") == selected_acapella:
						config["Audiotracks"]["Acapella"] = [track]
						break
	elif type == "playlist":
		pass


func ScanFolder():
	var path: String
	if type == "single":
		path = BasePath + "/" + FolderName + "/Audio"
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var folder_name = dir.get_next()
			
			while folder_name != "":
				if dir.current_is_dir():
					FolderData[folder_name] = true
				folder_name = dir.get_next()
			dir.list_dir_end()
		else:
			Debugger.debug("PresetScene.gd", "ScanFolder()", "Failed to open folder: " + path)
	elif type == "playlist":
		path = BasePath + "/" + FolderName
	Debugger.info("PresetScene.gd", "ScanFolder()", "Path for scanning = " + path)
	FolderData = {}

	Debugger.debug("PresetScene.gd", "ScanFolder()", str(FolderData))

func load_playlists():
	var path = BasePath + "/[Playlists]"  # Путь к папке с плейлистами
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and not file_name.begins_with("."):  # Игнорируем скрытые файлы
				var playlist_name = file_name.replace(".json", "")  # Убираем расширение .json
				playlists[playlist_name] = path + "/" + file_name  # Сохраняем путь к файлу
				PlaylistCheckBox.add_item(playlist_name)  # Добавляем имя плейлиста в CheckBox
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		Debugger.error("PresetScene.gd", "load_playlists()", "Failed to open directory: " + path)

func load_playlist(playlist_path: String) -> Dictionary:
	var file = FileAccess.open(playlist_path, FileAccess.READ)
	if file:
		var json = JSON.new()  # Создаем экземпляр JSON
		var json_result = json.parse(file.get_as_text())  # Используем экземпляр для парсинга
		if json_result == OK:  # Проверяем успешность парсинга
			return json.get_data()  # Получаем данные
		else:
			Debugger.error("PresetScene.gd", "load_playlist()", "Failed to parse JSON: " + json.get_error_message())
	else:
		Debugger.error("PresetScene.gd", "load_playlist()", "Failed to open playlist file: " + playlist_path)
	return {}

func load_song_config(song_path: String) -> Dictionary:
	var config_path = BasePath + "/" + song_path + "/config.json"  # Полный путь к config.json
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file:
		var json = JSON.new()  # Создаем экземпляр JSON
		var json_result = json.parse(file.get_as_text())  # Используем экземпляр для парсинга
		if json_result == OK:  # Проверяем успешность парсинга
			var config = json.get_data()  # Получаем данные
			config["global_path"] = BasePath + "/" + song_path  # Добавляем глобальный путь
			return config
		else:
			Debugger.error("PresetScene.gd", "load_song_config()", "Failed to parse JSON: " + json.get_error_message())
	else:
		Debugger.error("PresetScene.gd", "load_song_config()", "Failed to open config file: " + config_path)
	return {}

func pack_playlist() -> Dictionary:
	var playlist = {}
	if type == "single":
		playlist[1] = BasePath + "/" + FolderName
	elif type == "playlist":
		var selected_playlist = PlaylistCheckBox.get_item_text(PlaylistCheckBox.selected)  # Получаем выбранный плейлист
		var playlist_path = playlists.get(selected_playlist, "")  # Получаем путь к выбранному плейлисту
		if playlist_path:
			var raw_playlist = load_playlist(playlist_path)  # Загружаем сырой плейлист
			for key in raw_playlist.keys():
				var song_path = raw_playlist[key]  # Получаем путь к песне
				playlist[key] = song_path  # Добавляем в плейлист
	return playlist

func start_karaoke(playlist: Dictionary) -> void:
	var processed_playlist = {}
	for key in playlist.keys():
		var song_path = playlist[key]
		var config = load_song_config(song_path)  # Загружаем конфиг песни
		if config:
			processed_playlist[key] = config
	UIManager.show_ui("player_scene").import_playlist(processed_playlist)

func _on_back_btn_pressed() -> void:
	self.queue_free()

func _on_start_btn_pressed() -> void:
	var playlist = pack_playlist()
	print("/// ", playlist)
	if playlist:
		start_karaoke(playlist)
