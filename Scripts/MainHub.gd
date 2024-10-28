extends Node2D

# Словарь для хранения загруженных сцен
var scenes = {}

# Путь к SubViewport
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport

@onready var Music = load("res://MainMenu/BGMScene.tscn").instantiate()

func _ready():
	# Загрузка стартовой сцены
	load_scene("res://Scenes/MainMenu.tscn")
	#load_scene("res://MainMenu/BGMScene.tscn")
	await get_tree().create_timer(0.1).timeout
	#get_tree().root.add_child(Music)
	Music.z_index = 0
	Music.mouse_filter = Control.MOUSE_FILTER_IGNORE

	
# Функция для загрузки и отображения сцены
func load_scene(scene_path: String):
	# Если сцена уже загружена, просто показываем её
	if scenes.has(scene_path):
		sub_viewport.remove_child(sub_viewport.get_child(0))
		sub_viewport.add_child(scenes[scene_path])
		return

	# Загружаем сцену
	var scene = load(scene_path).instantiate()
	scenes[scene_path] = scene
	# Очистка старой сцены, если она есть
	if sub_viewport.get_child_count() > 0:
		sub_viewport.remove_child(sub_viewport.get_child(0))
	sub_viewport.add_child(scene)

# Пример использования для загрузки других сцен
func load_main_menu():
	load_scene("res://scenes/MainMenu.tscn")

func load_settings():
	load_scene("res://scenes/Settings.tscn")

func load_catalog():
	load_scene("res://scenes/Catalog.tscn")
