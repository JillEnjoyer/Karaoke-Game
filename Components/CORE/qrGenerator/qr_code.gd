extends Control

# Путь к qrGenerator.exe
var qrGenerator = ProjectSettings.globalize_path("res://Extensions/qrGenerator.exe")

func _ready():
	var link = "https://example.com1111111"
	var image_texture = generate_qr_code(link)
	
	if image_texture:
		$TextureRect.texture = image_texture  # Устанавливаем текстуру
		# Проверяем, что текстура установлена
		print("Текстура установлена с размером: ", image_texture.get_width(), "x", image_texture.get_height())
	else:
		print("Ошибка при создании текстуры.")

func generate_qr_code(link: String) -> ImageTexture:
	var output = []
	
	# Запускаем Python скрипт, передаем ссылку и получаем байтовые данные
	var arguments = [link]
	var exit_code = OS.execute(qrGenerator, arguments, output)
	if exit_code != OK:
		print("Ошибка при запуске qrGenerator.py")
		return null
	
	var width = 0
	var height = 0
	var pixel_data = ""

	# Прочитаем данные из вывода
	var reading_pixels = false
	for line in output:
		line = line.strip_edges()

		# Находим первый разделитель ";" для извлечения размеров и пикселей
		var separator_index = line.find(";")
		if separator_index != -1:
			# Разделяем строку на две части
			var size_data = line.substr(0, separator_index).split(",")
			width = int(size_data[0])
			height = int(size_data[1])
			
			# Пиксели начинаются после первого ";"
			pixel_data = line.substr(separator_index + 1)  # Получаем всю строку с пикселями
			break  # Мы закончили обработку первой строки с размерами и пикселями

	# Создаем изображение из полученных данных
	var base = Image.new()
	var image = base.create_empty(width, height, false, Image.FORMAT_RGB8)  # Создаем пустое изображение
	var x = 0
	var y = 0
	var index = 0  # Для отслеживания текущего символа в строке пикселей
	var data_length = pixel_data.length()
	# Обрабатываем строку с пикселями
	while index < data_length:
		var current_char = pixel_data[index]
		if current_char == ",":
			# Если это запятая, двигаемся по оси X
			x += 1
		elif current_char == ";":
			# Если это точка с запятой, переходим на новую строку
			y += 1
			x = 0  # Сброс X
		else:
			# Пиксель, который будет либо черным, либо белым
			var color = Color.WHITE  # Белый по умолчанию
			if current_char == "1":  # Черный пиксель
				color = Color.BLACK
			image.set_pixel(x, y, color)  # Устанавливаем пиксель

		index += 1  # Переходим к следующему символу в строке
	
	# Создаем текстуру из изображения
	var texture = ImageTexture.new().create_from_image(image)
	if texture:  # Создаем текстуру из изображения
		print("Текстура успешно создана с размерами: ", texture.get_width(), "x", texture.get_height())
	else:
		print("Ошибка при создании текстуры.")

	return texture
