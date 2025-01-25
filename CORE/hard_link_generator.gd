extends Node

# Укажите глобальный путь к папке каталога (где хранятся песни)
var global_path_to_folder = "D:/MusicLibrary"

# Имя ссылки в корне проекта
var link_name_in_project = "Music"

func _ready():
	if OS.has_feature("windows"):
		create_hardlink_windows()
	else:
		print("Hard links are only supported on Windows with mklink /J.")
		print("On Linux/macOS, please use symlinks (modify script if needed).")

# Создаём жёсткую ссылку для Windows
func create_hardlink_windows():
	var project_root = ProjectSettings.globalize_path("res://")  # Получаем путь до корня проекта
	var link_path = project_root + "/" + link_name_in_project

	# Проверяем, существует ли ссылка
	var dir = DirAccess.new.call()
	if dir.dir_exists(link_path):
		print("Hard link already exists:", link_path)
		return
	
	# Формируем команду mklink /J
	var command = 'mklink /J "{}" "{}"'.format(link_path.replace("/", "\\"), global_path_to_folder.replace("/", "\\"))

	# Выполняем команду через cmd
	var result = OS.execute("cmd", ["/c", command], [])
	
	if result == OK:
		print("Hard link created successfully:", link_path)
	else:
		print("Failed to create hard link. Ensure paths are correct and files are accessible.")
