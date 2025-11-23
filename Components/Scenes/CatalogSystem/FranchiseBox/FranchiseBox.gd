extends Control

var franchise_name: String
var franchise_path: String

const ICON_SIZE = 220  # Размер иконки
const BOX_WIDTH = 1675  # Ширина прямоугольника
const BOX_HEIGHT = 250  # Высота прямоугольника
const TITLE_SIZE = 280  # Размер шрифта заголовка
const DESCRIPTION_SIZE = 20  # Размер шрифта описания
const BACKGROUND_OPACITY = 0.5  # Прозрачность фона

# Создание ссылки на динамический шрифт
var title_font: FontFile

func _ready():
	# Создаем объект DynamicFont
	title_font = FontFile.new()

	# Загрузка файла шрифта
	#var font_data = load("res://Fonts/Comic Sans MS.ttf") as FontFile
	var font_data = load("res://Fonts/Comic Sans MS.ttf")
	if font_data == null:
		print("Ошибка: файл шрифта не загружен.")
	else:
		#title_font.data = font_data
		title_font.fixed_size = TITLE_SIZE  # Устанавливаем размер шрифта
	# Вызов setup функции для примера
	#setup("HazbinHotel", "res://Catalog/")

func setup(name: String, path: String):
	franchise_name = name
	franchise_path = path

	# Устанавливаем минимальный размер для контейнера
	custom_minimum_size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	self.add_theme_constant_override("separation", 10)  # Задает отступы

	# Создаем фон
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, BACKGROUND_OPACITY)  # Черный с прозрачностью 75%
	background.size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	add_child(background)

	# Создаем иконку
	var icon_path = franchise_path + "Icon.png"
	if FileAccess.file_exists(icon_path):
		var icon_texture = load(icon_path)
		var icon = TextureRect.new()
		icon.texture = icon_texture
		icon.set_stretch_mode(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)  # Сохраняем пропорции и центрируем иконку
		icon.set_scale(Vector2(ICON_SIZE / icon_texture.get_size().x, ICON_SIZE / icon_texture.get_size().y))  # Масштабируем иконку
		icon.position = Vector2(15, (BOX_HEIGHT - ICON_SIZE) / 2)  # Располагаем иконку слева с отступом
		add_child(icon)
	else:
		print("Ошибка: файл Icon.png не найден в пути: " + icon_path)

	# Создаем заголовок
	var title_label = Label.new()
	title_label.text = franchise_name
	title_label.position = Vector2(ICON_SIZE + 40, 20)  # Располагаем заголовок справа от иконки
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Выравниваем текст по левому краю
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER  # Центрируем текст по вертикали
	#title_label.add_theme_font_override("font", title_font)  # Применяем шрифт DynamicFont
	title_label.get_theme_font("font")
	add_child(title_label)

	# Создаем описание
	var description = "Описание отсутствует."
	var description_path = franchise_path + "Data.txt"
	if FileAccess.file_exists(description_path):
		var file = FileAccess.open(description_path, FileAccess.READ)
		if file:
			description = file.get_as_text()
			file.close()

	var description_label = Label.new()
	description_label.text = description
	description_label.position = Vector2(ICON_SIZE + 40, 60)  # Располагаем описание под заголовком
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#description_label.add_theme_font_override("font", title_font)  # Применяем шрифт DynamicFont
	description_label.get_theme_font("font")
	add_child(description_label)

	# Подключаем сигнал нажатия
	self.connect("gui_input", Callable(self, "_on_franchise_box_pressed"))

func _on_franchise_box_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		print("Франшиза выбрана: ", franchise_name)
		# Здесь вы можете вызвать метод load_songs или другой метод
