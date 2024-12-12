extends Control

@onready var video_node = Video.new()
@onready var audio_node = $AudioStreamPlayer

# Настройки таймера и логика кадров
var timer = 1.0 / 30.0  # Частота обновления для вывода кадров
var time_passed = 0.0
var playback_speed = 1.0  # Начальная скорость воспроизведения
var is_playing = false
var playtime = 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("stop"):
		is_playing = !is_playing
		if is_playing == true:
			play_video()
		else:
			pause_video()
		print(is_playing)
	elif event.is_action_pressed("left"):
		seek_video(-5.0)
	elif event.is_action_pressed("right"):
		seek_video(5.0)

func _ready():
	# Открытие видеофайла
	var result = video_node.open("W:/Projects/Godot/Karaoke/karaoke-game/Catalog/Hazbin Hotel/Respectless/[Video]Respectless.ogv")
	var arr = video_node.get_file_meta("W:/Projects/Godot/Karaoke/karaoke-game/Catalog/Hazbin Hotel/Respectless/[Video]Respectless.ogv")
	print(arr)
	if result == OK:
		print("Видео успешно открыто!")
	else:
		print("Ошибка при открытии видео: ", result)

	# Настройка аудио и начало воспроизведения
	audio_node.stream = load("res://Catalog/Hazbin Hotel/Respectless/Audio/[Acapella]Respectless1.mp3") as AudioStream
	audio_node.play()
	is_playing = true

func _process(delta: float) -> void:
	if is_playing:
		time_passed += delta * playback_speed
		playtime += delta * playback_speed
		if time_passed >= timer:
			time_passed -= timer
			# Получение следующего кадра видео и установка его на TextureRect
			$TextureRect.texture.set_image(video_node.next_frame())

# Команды для управления видео
func play_video():
	audio_node.stream_paused = false

func pause_video():
	audio_node.stream_paused = true

func set_playback_speed(speed: float):
	# Изменение скорости воспроизведения
	playback_speed = speed
	audio_node.pitch_scale = playback_speed  # Синхронизация звука с видео

func seek_video(seconds: float):
	# Перемотка на заданное время
	var ss = playtime * 30 + seconds * 30
	video_node.seek_frame(ss)
	print("seeked time:" + str(ss))
	print(str(playtime * 30) + str(seconds * 30))
	#audio_node.seek(seconds)
	playtime += seconds
