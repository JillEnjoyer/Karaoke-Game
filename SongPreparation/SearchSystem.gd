extends Control

var current_path: String = "res://Catalog/Hazbin Hotel/"
var dir: DirAccess
var chosen_files: Dictionary = {}


func _ready():
	pass
	

func clear_children(container: Control):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func update_file_list():
	# Очистка списка
	clear_children($ScrollContainer_FM/VBoxContainer)

	if dir == null:
		return

	var entries = dir.get_files() + dir.get_directories()
	for file_name in entries:
		var is_folder = dir.file_exists(file_name) == false
		var tile = create_tile(file_name, is_folder)
		$ScrollContainer_FM/VBoxContainer.add_child(tile)

func create_tile(file_name: String, is_folder: bool) -> Button:
	var button = Button.new()
	button.text = file_name
	button.custom_minimum_size = Vector2(600, 50)

	# Настройка размера текста
	var font = FontFile.new()
	#font.font_data = load("res://your_font.ttf")
	font.fixed_size = 48
	button.add_theme_font_override("font", font)
	
	if is_folder:
		button.text += "/"
	button.connect("pressed", Callable(self, "_on_tile_pressed").bind(file_name, button))

	return button

func _on_tile_pressed(file_name: String, button: Button):
	var full_path = current_path + "/" + file_name

	if chosen_files.has(file_name):
		print("Файл уже добавлен:", file_name)
		return

	if DirAccess.open(full_path):
		current_path = full_path
		$PathLineEdit.text = current_path
		dir = DirAccess.open(current_path)
		update_file_list()
		print("Открыта папка:", full_path)
		return
	
	chosen_files[file_name] = full_path

	var new_button = create_tile(file_name, false)
	$ScrollContainer_CI/VBoxContainer.add_child(new_button)



func transfer_tile_to_chosen_items(file_name: String, button: Button):
	if file_name in chosen_files:
		print("Файл уже добавлен:", file_name)
		return
	
	chosen_files[file_name] = true

	var new_button = Button.new()
	new_button.text = button.text
	new_button.custom_minimum_size = button.custom_minimum_size
	new_button.add_theme_font_override("font", button.get_theme_font("font"))
	
	new_button.connect("pressed", Callable(self, "_on_remove_tile").bind(file_name, new_button))

	$ScrollContainer_CI/VBoxContainer.add_child(new_button)

func _on_remove_tile(file_name: String, button: Button):
	chosen_files.erase(file_name)
	
	$ScrollContainer_CI/VBoxContainer.remove_child(button)
	button.queue_free()



func _on_path_changed(new_path: String):
	if DirAccess.open(new_path) != null:
		current_path = new_path
		dir = DirAccess.open(current_path)
		update_file_list()
	else:
		print("Неверный путь:", new_path)

func _on_path_focus_exited():
	if DirAccess.open($PathLineEdit.text) == null:
		$PathLineEdit.text = current_path
		print("Путь недоступен, возвращаемся к:", current_path)


func instantiate_project():
	"""
	Обработка выбранных файлов для создания проекта.
	"""
	if chosen_files.size():
		print("Нет выбранных файлов для проекта.")
		return

	var init_window = $InitializationWindow
	init_window.visible = true

	var apply_button = $InitializationWindow.get_node("ApplyButton")
	apply_button.connect("pressed", Callable(self, "_on_apply_pressed").bind(chosen_files))



func _on_apply_pressed(chosen_files: Dictionary):
	var project_name = $InitializationWindow.get_node("FolderNameLineEdit").text

	if project_name == "":
		print("Название проекта не указано.")
		return

	var project_path = "res://Catalog/" + project_name
	var dir = DirAccess.open("res://")
	if dir == null:
		print("Не удалось получить доступ к папке res://")
		return

	if !dir.dir_exists(project_path):
		if !dir.make_dir_recursive(project_path):
			print("Не удалось создать папку:", project_path)
			return

	var setup_path = project_path + "/Setup.cfg"
	var file = FileAccess.open(setup_path, FileAccess.ModeFlags.WRITE)
	if file:
		for file_name in chosen_files.keys():
			var full_path = chosen_files[file_name]
			file.store_line(file_name + ":" + full_path)  # Сохраняем имя и путь в файл

			var target_path = project_path + "/" + file_name
			if !FileAccess.file_exists(target_path):  # Если файл не существует
				var file_copy_result = copy_file(full_path, target_path)
				if file_copy_result:
					print("Файл успешно скопирован:", full_path)
				else:
					print("Не удалось скопировать файл:", full_path)
			else:
				print("Файл уже существует в целевой папке:", target_path)
		file.close()

	chosen_files.clear()
	clear_children($ScrollContainer_CI/VBoxContainer)

	var tween = $Tween
	tween.interpolate_property(
		$ScrollContainer_FM, "rect_scale", 
		Vector2.ONE, Vector2(0.0, 1.0), 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT
	)
	tween.start()


func copy_file(source_path: String, destination_path: String) -> bool:
	var file = FileAccess.open(source_path, FileAccess.ModeFlags.READ)
	if file:
		var file_data = file.get_buffer(file.get_length())
		file.close()

		var target_file = FileAccess.open(destination_path, FileAccess.ModeFlags.WRITE)
		if target_file:
			target_file.store_buffer(file_data)
			target_file.close()
			return true
		else:
			print("Ошибка при открытии целевого файла для записи:", destination_path)
			return false
	else:
		print("Ошибка при открытии исходного файла:", source_path)
		return false
