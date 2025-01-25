extends Control

@onready var log = Core.get_node("Debugger")

var player_scene_fullscreen = false

@onready var PlayerScene = $PlayerScene
#@onready var SearchSystem = $SearchSystem
@onready var animation_player = $AnimationPlayer
@onready var file_dialog = FileDialog.new()
@onready var context_menu = PopupMenu.new()
@onready var control_container = Control.new()  # Контейнер для событий

const PLAYER_SCENE_WINDOW_RATIO = 1.5

func _ready() -> void:
	file_dialog_init()
	PlayerScene.size = PlayerScene.size * PLAYER_SCENE_WINDOW_RATIO
	PlayerScene.debugging = true
	PlayerScene.get_node("TextureRect").texture = preload("res://icon.svg")


func _input(event):
	if Input.is_action_just_pressed("pause"):
		leave_scene()
	elif Input.is_action_just_pressed("expand"):
		log.debug("", "", "")
		switch_player_scene_mode()


func leave_scene():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure? All unsaved changes will be lost!"
	dialog.title = "Quit confirmation"
	dialog.get_ok_button().text = "Yes"
	dialog.connect("confirmed", Callable(self, "_on_yes_pressed"))

	add_child(dialog)
	dialog.popup_centered()


func _on_yes_pressed():
	var main_menu = preload("res://MainMenu/MainMenu.tscn").instantiate()
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		current_scene.queue_free()

	get_tree().root.add_child(main_menu)
	get_tree().set_current_scene(main_menu)


func switch_player_scene_mode():
	if not player_scene_fullscreen:
		animation_player.play("Expand")
		print("animation played forward")
		print("size :", PlayerScene.size)
	elif player_scene_fullscreen:
		animation_player.play_backwards("Expand")
		print("animation played back")
		print("size :", PlayerScene.size)
	player_scene_fullscreen = not player_scene_fullscreen

func file_dialog_init():
	"""
	Настраиваем FileDialog для выбора нескольких файлов из любой папки.
	"""
	add_child(file_dialog)  # Добавляем в сцену
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES  # Разрешаем выбирать несколько файлов
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # Разрешаем глобальные пути (например, C:/)
	#file_dialog.add_filter("*.png ; PNG Images")  # Фильтры для изображений
	#file_dialog.add_filter("*.jpg ; JPG Images")
	#file_dialog.title = "Выберите изображения"
	file_dialog.visible = true
	
	# Подключаем сигнал для обработки выбранных файлов
	file_dialog.files_selected.connect(_on_files_selected)
	# Теперь контейнер ловит клики мыши
	control_container.mouse_filter = Control.MOUSE_FILTER_STOP
	control_container.gui_input.connect(_on_right_click)

func open_dialog():
	"""
	Открываем FileDialog вручную.
	"""
	file_dialog.popup_centered_ratio(0.8)

func _on_files_selected(paths: PackedStringArray):
	"""
	Обрабатываем выбранные файлы.
	"""
	print("Выбраны файлы:", paths)

func _on_right_click(event):
	"""
	Проверяем, был ли клик правой кнопкой мыши.
	"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		context_menu.set_position(event.global_position)  # Устанавливаем позицию меню
		context_menu.popup()  # Показываем меню

func _on_menu_selected(id: int):
	"""
	Выполняем действие в зависимости от выбранного пункта контекстного меню.
	"""
	match id:
		0:
			print("Открываем файл...")
		1:
			print("Скопировали путь!")
		2:
			print("Удаляем файл...")

func handle_selected_files(files: PackedStringArray):
	"""
	Функция для обработки выбранных файлов.
	Можно сделать с ними что угодно.
	"""
	for file in files:
		print("Обрабатываем файл:", file)
		# Здесь можно добавить свою логику обработки файла
