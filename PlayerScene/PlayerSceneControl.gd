extends Control

@onready var video_node = Video.new()
@onready var VoiceChannelContainer = $HBox # Контейнер для управления каналами



# Объявление глобальных переменных
var VideoLink: String = ""
var InstrumentalLink: String = ""
var AcapellaList: Dictionary = {} # Словарь для акапелл персонажей
var SubtitlesList: Array = []
var CharacterList: Dictionary = {}

var video_position = 0.0
var instrumental_position = 0.0  # Позиция для инструментала
var acapella_positions: Dictionary = {}  # Словарь для позиций акапелл
var current_subtitle_line = 0  # Индекс текущей строки субтитров при паузе

var instrumental_player: AudioStreamPlayer = null
var acapella_players: Dictionary = {} # Словарь для плееров акапелл

var VoiceChannelControlScene = preload("res://PlayerScene/VoiceChannelControl.tscn")
var PauseMenuScene = preload("res://PauseMenu.tscn") # Добавление сцены паузы
var TimerScene = preload("res://TimerScene.tscn") # Таймер перед стартом
var TimeSlider = preload("res://TimeSlider.tscn").instantiate()

# Настройки таймера и логика кадров
var timer = 1.0 / 37.0  # Частота обновления для вывода кадров
var time_passed = 0.0
var playback_speed = 1.0  # Начальная скорость воспроизведения
var is_playing = false
var playtime = 0.0


func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	#Video.custom_minimum_size = screen_size
	
	print("Screen Size: ", screen_size)
	# Запуск таймера перед началом воспроизведения


func init(franchise_name: String, song_name: String, performer_name: String, mode: String) -> void:
	print("Init Launched")
	
	var main_path = "res://Catalog/" + franchise_name + "/" + song_name + "/"
	var BaseAudioPath = main_path + "Audio/"
	var BaseAcapellaPath = BaseAudioPath + performer_name + "/"
	var main_file = main_path + "Config.txt"
	var BaseSubtitlePath = main_path + "Subtitles/"

	if not FileAccess.file_exists(main_file):
		print("Main file does not exist: ", main_file)
		return

	# Читаем конфигурационный файл
	parse_config(main_file)

	# Загружаем данные
	load_video(franchise_name, song_name) # Загружаем видео
	load_instrumental(BaseAudioPath) # Загружаем инструментал
	load_acapella(BaseAcapellaPath) # Загружаем акапеллы персонажей
	TimeSlider.connect("h_slider_value_changed_signal", Callable(self, "seek_video"))
	start_timer_before_play()


# Чтение конфигурационного файла
func parse_config(config_path: String) -> void:
	var file = FileAccess.open(config_path, FileAccess.READ)
	var current_acapella_group = ""
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		print(line)
		
		if line.begins_with("[Video]"):
			VideoLink = line.replace("[Video]", "").strip_edges()
			print("VideoLink extracted: ", VideoLink)
		elif line.begins_with("[Instrumental]"):
			InstrumentalLink = line.replace("[Instrumental]", "").strip_edges()
			print("InstrumentalLink extracted: ", InstrumentalLink)
		elif line.begins_with("[Acapella]"):
			current_acapella_group = line.replace("[Acapella]", "").strip_edges()
			AcapellaList[current_acapella_group] = []  
			print("Acapella group found: ", current_acapella_group)
		elif line.begins_with("[Character]") and current_acapella_group != "":
			var character_name = line.replace("[Character]", "").strip_edges()  
			AcapellaList[current_acapella_group].append(character_name)  
			CharacterList[character_name] = current_acapella_group  
			print("Character added: ", character_name, " -> ", current_acapella_group)
		elif line.begins_with("[Subtitles]"):
			var subtitle_info = line.replace("[Subtitles]", "").strip_edges()
			SubtitlesList.append(subtitle_info)
			print("Subtitles added: ", subtitle_info)

	file.close()


# Загрузка видео
func load_video(franchise_name: String, song_name: String) -> void:
	var video_path = "res://Catalog/" + franchise_name + "/" + song_name + "/" + VideoLink
	var absolute_video_path = ProjectSettings.globalize_path(video_path)
	print("Trying to load video from: ", absolute_video_path)

	if FileAccess.file_exists(absolute_video_path):
		var result = video_node.open(absolute_video_path)
		if result == OK:
			print("Видео успешно открыто!")
		else:
			print("Ошибка при открытии видео: ", result)
	else:
		print("Video file not found: ", absolute_video_path)
		
	

# Загрузка инструментала
func load_instrumental(path: String) -> void:
	var instrumental_file = path + InstrumentalLink
	print("Trying to load instrumental from: ", instrumental_file)  # Отладочное сообщение
	if FileAccess.file_exists(instrumental_file):
		instrumental_player = AudioStreamPlayer.new()
		instrumental_player.stream = load(instrumental_file) as AudioStream
		add_child(instrumental_player)
		print("Instrumental loaded successfully.")
	else:
		print("Instrumental file not found: ", instrumental_file)


# Загрузка акапелл персонажей
func load_acapella(base_path: String) -> void:
	print("Acapella list: ", AcapellaList)
	for acapella_group in AcapellaList.keys():
		for character_name in AcapellaList[acapella_group]:
			var acapella_file = base_path + character_name + ".mp3"
			print("Trying to load acapella for character ", character_name, " from: ", acapella_file)
			if FileAccess.file_exists(acapella_file):
				var acapella_player = AudioStreamPlayer.new()
				acapella_player.stream = load(acapella_file) as AudioStream
				add_child(acapella_player)
				acapella_players[character_name] = acapella_player

				# Создание канала управления голосом
				create_voice_channel_control(character_name)
			else:
				print("Acapella file not found: ", acapella_file)


#////////////////////////////////////////////////////
func _process(delta: float) -> void:
	if is_playing:
		time_passed += delta * playback_speed
		playtime += delta * playback_speed
		if time_passed >= timer:
			time_passed = 0.0
			# Получение следующего кадра видео и установка его на TextureRect
			$TextureRect.texture.set_image(video_node.next_frame())
#////////////////////////////////////////////////////


func seek(time: float) -> void:
	if Video:
		#Video.seek(time)
		pass
	if instrumental_player:
		instrumental_player.seek(time)
	for player in acapella_players.values():
		player.seek(time)
#////////////////////////////////////////////

func set_playback_speed(speed: float):
	# Изменение скорости воспроизведения
	playback_speed = speed
	#audio_node.pitch_scale = playback_speed  # Синхронизация звука с видео

func seek_video(seconds: float):
	# Перемотка на заданное время
	var ss = playtime * 30 + seconds * 30
	video_node.seek_frame(ss)
	print("seeked time:" + str(ss))
	print(str(playtime * 30) + str(seconds * 30))
	#audio_node.seek(seconds)
	playtime += seconds


# Определение текущей строки субтитров
func get_current_subtitle_line(time: float) -> int:
	for i in range(SubtitlesList.size()):
		var subtitle_time = float(SubtitlesList[i].split(",")[0]) # Предположим формат: "время_начала,время_конца,текст"
		if subtitle_time > time:
			return i - 1  # Возвращаем предыдущую строку
	return SubtitlesList.size() - 1


# Сохранение позиции и строки при паузе
func show_pause_menu() -> void:
	if get_node("/root/PlayerScene").has_node("PauseMenu"):
		print("Pause menu already exists, not spawning a new one.")
		return  # Если меню уже существует, не создаем новое
	
	var pause_menu_instance = PauseMenuScene.instantiate()
	add_child(pause_menu_instance)

	# Подключаемся к сигналу Continue из меню паузы
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	
	pause_all()

func pause_all() -> void:
	is_playing = false

	instrumental_position = instrumental_player.get_playback_position()
	instrumental_player.stream_paused = true

	for player in acapella_players.values():
		acapella_positions[player] = player.get_playback_position()
		player.stream_paused = true
	
	current_subtitle_line = get_current_subtitle_line(instrumental_position)

# Возобновление с начала строки после паузы
func resume_all() -> void:
	if Video:
		#var subtitle_time = float(SubtitlesList[current_subtitle_line].split(",")[0])
		
		is_playing = true
		
	if instrumental_player:
		# Устанавливаем начальную позицию и запускаем с неё
		#instrumental_player.play(instrumental_position)
		instrumental_player.seek(instrumental_position)
		instrumental_player.stream_paused = false

	for player in acapella_players.values():
		#player.seek(acapella_positions[player])
		#player.seek(0.1)
		player.stream_paused = false


# Создание и добавление VoiceChannelControl для каждого персонажа
func create_voice_channel_control(character_name: String) -> void:
	var control_instance = VoiceChannelControlScene.instantiate()
	control_instance.get_node("Ch_NameLbl").text = character_name
	VoiceChannelContainer.add_child(control_instance)
	
	control_instance.connect("value_changed_signal", Callable(self, "on_value_changed"))

func on_value_changed(value) -> void:
	print("value changed")


# Реакция на нажатие Escape для вызова меню паузы
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		show_pause_menu()


# Запуск таймера перед стартом игры
func start_timer_before_play() -> void:
	var timer_instance = TimerScene.instantiate()
	add_child(timer_instance)
	
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))
	#_on_timer_ready_to_start()
	#play_all()

# Обработка сигнала Continue
func _on_pause_menu_continue() -> void:
	print("Continue signal received, resuming playback.")
	resume_all()  # Возобновляем воспроизведение всех потоков

func _on_timer_ready_to_start() -> void:
	print("Timer finished, starting playback.")
	resume_all()
