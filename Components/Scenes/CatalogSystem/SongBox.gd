# SongBox.gd
extends VBoxContainer

func setup(song_name: String, song_path: String):
	name = song_name
	add_theme_constant_override("separation", 10)

	# Создаем иконку
	var icon_texture = load(song_path + "Icon.png")
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(icon)

	# Создаем заголовок
	var title_label = Label.new()
	title_label.text = song_name
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(title_label)

	# Загружаем описание с использованием FileAccess
	var description = "Описание отсутствует."
	var file_path = song_path + "Data.txt"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			description = file.get_as_text()
			file.close()
		else:
			print("Ошибка: не удалось открыть файл для чтения: " + file_path)
	else:
		print("Ошибка: файл Data.txt не найден в пути: " + file_path)

	# Создаем описание
	var description_label = Label.new()
	description_label.text = description
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(description_label)

	connect("gui_input", Callable(self, "_on_song_box_pressed"))

func _on_song_box_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		print("Песня выбрана: ", name)
		get_tree().call_group("root", "load_media", name)
