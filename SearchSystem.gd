extends Control

var current_path: String = "res://Catalog/Hazbin Hotel/"
var dir: DirAccess

func _ready():
	# Настраиваем LineEdit для отображения пути
	$PathLineEdit.text = current_path
	$PathLineEdit.connect("text_changed", Callable(self, "_on_path_changed"))
	$PathLineEdit.connect("focus_exited", Callable(self, "_on_path_focus_exited"))

	dir = DirAccess.open(current_path)
	if dir == null:
		print("Не удалось открыть папку:", current_path)
	else:
		update_file_list()

func clear_children(container: Control):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func update_file_list():
	# Очистка списка
	clear_children($ScrollContainer/VBoxContainer)

	if dir == null:
		return

	var entries = dir.get_files() + dir.get_directories()
	for file_name in entries:
		var is_folder = dir.file_exists(file_name) == false
		var tile = create_tile(file_name, is_folder)
		$ScrollContainer/VBoxContainer.add_child(tile)

func create_tile(file_name: String, is_folder: bool) -> Button:
	var button = Button.new()
	button.text = file_name
	button.custom_minimum_size = Vector2(600, 100)  # Размер кнопки

	# Настройка размера текста
	var font = FontFile.new()
	#font.font_data = load("res://your_font.ttf")  # Замените на путь к вашему шрифту
	font.fixed_size = 48  # Размер текста
	button.add_theme_font_override("font", font)
	
	if is_folder:
		button.text += "/"
	button.connect("pressed", Callable(self, "_on_tile_pressed").bind(file_name))
	return button


func _on_tile_pressed(file_name: String):
	var new_path = current_path + "/" + file_name
	if DirAccess.open(new_path) != null:  # Если это папка
		current_path = new_path
		$PathLineEdit.text = current_path  # Обновляем путь в LineEdit
		dir = DirAccess.open(current_path)
		update_file_list()
	else:  # Если это файл
		print("Открыть файл:", new_path)

func _on_path_changed(new_path: String):
	# Проверка пути при изменении текста
	if DirAccess.open(new_path) != null:
		current_path = new_path
		dir = DirAccess.open(current_path)
		update_file_list()
	else:
		print("Неверный путь:", new_path)

func _on_path_focus_exited():
	# При потере фокуса вернуть корректный путь
	if DirAccess.open($PathLineEdit.text) == null:
		$PathLineEdit.text = current_path
		print("Путь недоступен, возвращаемся к:", current_path)
