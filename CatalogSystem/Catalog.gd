# Main.gd
extends Control

@export var catalog_container: VBoxContainer
var Development = true

# Подключаем скрипты
const FranchiseBox = preload("res://CatalogSystem/FranchiseBox.gd")
const SongBox = preload("res://CatalogSystem/SongBox.gd")

func _ready():
	# Убедитесь, что catalog_container назначен
	if catalog_container == null:
		catalog_container = $ScrollContainer/VBoxContainer

	if catalog_container:
		load_franchises()
	else:
		print("Ошибка: catalog_container не инициализирован")

func load_franchises():
	var catalog_path = ""
	if Development:
		catalog_path = "W:/Projects/Godot/Karaoke/karaoke-game/Catalog"
	else:
		catalog_path = "root:/Catalog"
	
	print(OS.get_executable_path())
	#await get_tree().create_timer(2).timeout
	
	var dir = DirAccess.open(catalog_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and folder_name != "." and folder_name != "..":
				# Создаем прямоугольник для франшизы
				var franchise_box = FranchiseBox.new()
				franchise_box.setup(folder_name, catalog_path + "/" + folder_name + "/")
				catalog_container.add_child(franchise_box)
			folder_name = dir.get_next()
		dir.list_dir_end()

func load_songs(franchise_name: String):
	var franchise_path = "res://Catalog/" + franchise_name + "/"
	var dir = DirAccess.open(franchise_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and folder_name != "." and folder_name != "..":
				# Создаем прямоугольник для песни
				var song_box = SongBox.new()
				song_box.setup(folder_name, franchise_path + folder_name + "/")
				catalog_container.add_child(song_box)
			folder_name = dir.get_next()
		dir.list_dir_end()

# Функция для вызова из SongBox
func load_media(song_name: String):
	var song_path = "res://Catalog/" + song_name + "/"
	var dir = DirAccess.open(song_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				var file_parts = file_name.split(".")
				if file_parts.size() > 1:
					var file_extension = file_parts[file_parts.size() - 1].to_lower()
					if file_extension in ["mp3", "wav", "avi", "mp4"]:
						print("Найден файл: ", file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
