extends Control

@onready var texture_rect = $TextureRect

@onready var figure_path = "W:/Projects/Godot/Karaoke/Mat/Ext"
@onready var state = true
@onready var tex_path = []  # Массив для хранения путей
@onready var tex = []  # Массив загруженных текстур

func _ready() -> void:
	tex_init()
	anim_exec()

func tex_init():
	"""
	Загружает текстуры из указанной папки.
	"""
	var file_count = count_files_in_directory(figure_path)
	if file_count > 0:
		# Сортируем файлы по числовому значению имени
		tex_path.sort_custom(func(a, b): return extract_number(a) < extract_number(b))

		for n in range(file_count):
			if tex_path.size() > n:
				var image = Image.new()
				if image.load(tex_path[n]) == OK:
					var texture = ImageTexture.create_from_image(image)
					if texture:
						tex.append(texture)
						print("Загружено:", tex_path[n])
					else:
						print("Ошибка при создании текстуры:", tex_path[n])
				else:
					print("Ошибка при загрузке изображения:", tex_path[n])

func extract_number(filename: String) -> int:
	"""
	Извлекает числовую часть имени файла перед ".png".
	"""
	var regex = RegEx.new()
	regex.compile("\\d+")  # Ищем числа в строке
	var result = regex.search(filename)
	if result:
		return result.get_string().to_int()
	return 0  # Если нет чисел, возвращаем 0


func anim_exec():
	while state:
		for n in range(tex.size()):  # Используем размер массива tex
			print(n)
			texture_rect.texture = tex[n]  # Обновляем текстуру
			await get_tree().create_timer(0.075).timeout

func count_files_in_directory(path: String) -> int:
	"""
	Считает файлы в указанной папке и сохраняет пути в tex_path.
	Input: path (String) - путь к директории
	Output: (int) - количество файлов
	"""
	var dir = DirAccess.open(path)
	if dir == null:
		print("Ошибка: не удалось открыть директорию", path)
		return 0
	
	dir.list_dir_begin()
	var count = 0
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			tex_path.append(path + "/" + file_name)  # Добавляем путь в массив
			count += 1
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return count

func anim_stop():
	"""
	Останавливает анимацию.
	"""
	state = false
