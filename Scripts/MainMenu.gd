#MainMenu.gd
extends Control

@export var catalog_button: Button
@export var settings_button: Button
@export var quit_button: Button

func _ready():
	# Проверяем, что родительский контейнер существует
	var vbox_container = $VBoxContainer
	if vbox_container:
		print("VBoxContainer найден!")
		catalog_button = vbox_container.get_node("catalog_button")
		settings_button = vbox_container.get_node("settings_button")
		quit_button = vbox_container.get_node("quit_button")
		
		if catalog_button:
			print("catalog_button найден!")
			catalog_button.connect("pressed", Callable(self, "_on_catalog_button_pressed"))
		
		if settings_button:
			print("settings_button найден!")
			settings_button.connect("pressed", Callable(self, "_on_settings_button_pressed"))
		
		if quit_button:
			print("quit_button найден!")
			quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	else:
		print("VBoxContainer не найден!")

func _on_catalog_button_pressed():
	# Загружаем и открываем каталог
	var catalog_scene = load("res://CatalogSystem/Catalog.tscn").instantiate()
	if catalog_scene:
		var current_scene = get_tree().current_scene
		print(current_scene)
		if current_scene:
			current_scene.queue_free()  # Удаляем текущую сцену
			
			get_tree().root.add_child(catalog_scene)
			get_tree().set_current_scene(catalog_scene)  # Явно указываем новую сцену
			print(current_scene)
			catalog_scene.initial("Franchise")
		else:
			print("Ошибка: не удалось загрузить сцену Каталога!")

func _on_prepare_da_song_btn_pressed() -> void:
	var preparation_scene = load("res://Scenes/SongPreparationScene.tscn").instantiate()
	if preparation_scene:
		var current_scene = get_tree().current_scene
		print(current_scene)
		if current_scene:
			current_scene.queue_free()  # Удаляем текущую сцену
			
			get_tree().root.add_child(preparation_scene)
			get_tree().set_current_scene(preparation_scene)  # Явно указываем новую сцену
			print(current_scene)
			#preparation_scene.initial("Franchise")
		else:
			print("Ошибка: не удалось загрузить сцену Подготовки!")

func _on_settings_button_pressed():
	# Логика открытия настроек через основной хаб
	var main_hub = get_tree().root.get_node("MainHub")
	if main_hub:
		main_hub.load_settings()

func _on_quit_button_pressed():
	get_tree().quit()
