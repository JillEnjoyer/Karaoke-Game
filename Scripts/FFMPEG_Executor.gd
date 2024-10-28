extends Node

# Функция для вызова FFMPEG с нужными аргументами
func run_ffmpeg_command(input_file: String, output_file: String):
	var ffmpeg_path = "ffmpeg"  # Убедись, что FFMPEG доступен в системном пути
	var args = [
		"-i", input_file,  # Входной файл
		"-an",  # Удалить аудиопоток
		"-c:v", "libx264",  # Используем кодек H.264
		"-crf", "18",  # Оптимизация битрейта без потери качества
		"-preset", "slow",  # Оптимизация качества (можно выбрать fast, slow, slower и т.д.)
		"-pix_fmt", "yuv420p",  # Устанавливаем пиксельный формат для совместимости
		output_file  # Выходной файл
	]

	var output = []  # Массив для хранения вывода
	var error = []  # Массив для хранения ошибок

	# Выполняем команду FFMPEG
	var result = OS.execute(ffmpeg_path, args, output, error)
	if result == OK:
		print("FFMPEG executed successfully.")
		print("FFMPEG output: ", output.join("\n"))
	else:
		print("Failed to execute FFMPEG, error code: ", result)
		print("FFMPEG error output: ", error.join("\n"))

# Пример использования
func _ready():
	run_ffmpeg_command("res://input.mp4", "res://output.ogv")
