extends Control

@onready var video_node = Video.new()
@onready var voice_channel_container = $HBox # Контейнер для управления каналами
#@onready var slider_control = $TimeSlider

var base_var = {
	
}

var video_link = ""
var instrumental_link = ""
var acapella_list = {}
var subtitles_list = []
var character_list = {}

var video_position = 0.0
var instrumental_position = 0.0
var acapella_positions = {}
var current_subtitle_line = 0

var instrumental_player: AudioStreamPlayer = null
var acapella_players = {}

var voice_channel_control_scene = preload("res://PlayerScene/VoiceChannelControl.tscn")
var pause_menu_scene = preload("res://PauseMenu.tscn")
var timer_scene = preload("res://TimerScene.tscn")
var time_slider = preload("res://TimeSlider.tscn").instantiate()


var framerate = 1.0
var length = 1.0
var timer = 1.0
var time_passed = 0.0
var playback_speed = 1.0
var is_playing = false
var playtime = 0.0
var metadata_array = {}
var procent = 0.0

func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	#Video.custom_minimum_size = screen_size
	
	print("Screen Size: ", screen_size)
	# Запуск таймера перед началом воспроизведения


func init(franchise_name: String, song_name: String, performer_name: String, mode: String) -> void:
	print("Init Launched")
	
	var main_path = "res://Catalog/" + franchise_name + "/" + song_name + "/"
	var base_audio_path = main_path + "Audio/"
	var base_acapella_path = base_audio_path + performer_name + "/"
	var main_file = main_path + "Config.txt"
	var base_subtitle_path = main_path + "Subtitles/"

	if not FileAccess.file_exists(main_file):
		print("Main file does not exist: ", main_file)
		return
	parse_config(main_file)

	load_video(franchise_name, song_name)
	load_instrumental(base_audio_path)
	load_acapella(base_acapella_path)
	
	add_child(time_slider)
	time_slider.connect("h_slider_value_changed_signal", Callable(self, "on_slider_value_changed"))
	
	start_timer_before_play()


func on_slider_value_changed(value: float) -> void:
	print("recieved value: " + str(value))
	seek_video((length/100.0)*value)


func parse_config(config_path: String) -> void:
	var file = FileAccess.open(config_path, FileAccess.READ)
	var current_acapella_group = ""
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		print(line)
		
		if line.begins_with("[Video]"):
			video_link = line.replace("[Video]", "").strip_edges()
			print("VideoLink extracted: ", video_link)
		elif line.begins_with("[Instrumental]"):
			instrumental_link = line.replace("[Instrumental]", "").strip_edges()
			print("InstrumentalLink extracted: ", instrumental_link)
		elif line.begins_with("[Acapella]"):
			current_acapella_group = line.replace("[Acapella]", "").strip_edges()
			acapella_list[current_acapella_group] = []  
			print("Acapella group found: ", current_acapella_group)
		elif line.begins_with("[Character]") and current_acapella_group != "":
			var character_name = line.replace("[Character]", "").strip_edges()  
			acapella_list[current_acapella_group].append(character_name)  
			character_list[character_name] = current_acapella_group
			print("Character added: ", character_name, " -> ", current_acapella_group)
		elif line.begins_with("[Subtitles]"):
			var subtitle_info = line.replace("[Subtitles]", "").strip_edges()
			subtitles_list.append(subtitle_info)
			print("Subtitles added: ", subtitle_info)

	file.close()


func load_video(franchise_name: String, song_name: String) -> void:
	var video_path = "res://Catalog/" + franchise_name + "/" + song_name + "/" + video_link
	var absolute_video_path = ProjectSettings.globalize_path(video_path)
	print("Trying to load video from: ", absolute_video_path)
	
	if FileAccess.file_exists(absolute_video_path):
		metadata_array = video_node.get_file_meta(absolute_video_path)
		print(metadata_array)
		
		length = float(metadata_array.duration)
		framerate = float(metadata_array.fps)
		timer = timer/framerate
		
		var result = video_node.open(absolute_video_path)
		if result == OK:
			print("Video opened successfully!")
		else:
			print("Error with video opening: ", result)
	else:
		print("Video file not found: ", absolute_video_path)


func load_instrumental(path: String) -> void:
	var instrumental_file = path + instrumental_link
	print("Trying to load instrumental from: ", instrumental_file)  # Отладочное сообщение
	if FileAccess.file_exists(instrumental_file):
		instrumental_player = AudioStreamPlayer.new()
		instrumental_player.stream = load(instrumental_file) as AudioStream
		add_child(instrumental_player)
		print("Instrumental loaded successfully.")
		print(str(instrumental_player.playing))
	else:
		print("Instrumental file not found: ", instrumental_file)


func load_acapella(base_path: String) -> void:
	print("Acapella list: ", acapella_list)
	for acapella_group in acapella_list.keys():
		for character_name in acapella_list[acapella_group]:
			var acapella_file = base_path + character_name + ".mp3"
			print("Trying to load acapella for character ", character_name, " from: ", acapella_file)
			if FileAccess.file_exists(acapella_file):
				var acapella_player = AudioStreamPlayer.new()
				acapella_player.stream = load(acapella_file) as AudioStream
				add_child(acapella_player)
				print("Acapella " + acapella_file + " loaded successfully.")
				acapella_players[character_name] = acapella_player
				
				create_voice_channel_control(character_name)
			else:
				print("Acapella file not found: ", acapella_file)


#////////////////////////////////////////////////////
func _process(delta: float) -> void:
	#
	
	if is_playing:
		time_passed += delta * playback_speed
		playtime += delta * playback_speed
		if time_passed >= timer:
			time_passed -= timer
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


func set_playback_speed(speed: float):
	# Изменение скорости воспроизведения
	playback_speed = speed
	#audio_node.pitch_scale = playback_speed  # Синхронизация звука с видео

func seek_video(seconds: float):
	# Перемотка на заданное время
	var ss = seconds * framerate
	video_node.seek_frame(ss)
	print("seeked time:" + str(ss))
	#audio_node.seek(seconds)
	playtime += seconds


func get_current_subtitle_line(time: float) -> int:
	for i in range(subtitles_list.size()):
		var subtitle_time = float(subtitles_list[i].split(",")[0])
		if subtitle_time > time:
			return i - 1
	return subtitles_list.size() - 1


func show_pause_menu() -> void:
	if get_node("/root/PlayerScene").has_node("PauseMenu"):
		print("Pause menu already exists, not spawning a new one.")
		return

	var pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.connect("Continue", Callable(self, "_on_pause_menu_continue"))
	pause_all()


func pause_all() -> void:
	is_playing = false

	instrumental_player.stream_paused = true
	instrumental_position = instrumental_player.get_playback_position()

	for player in acapella_players.values():
		player.stream_paused = true
		acapella_positions[player] = player.get_playback_position()
	
	#current_subtitle_line = get_current_subtitle_line(instrumental_position)


func resume_all() -> void:
	is_playing = true

	if instrumental_player:
		#instrumental_player.play(instrumental_position)
		print("<Before> Instrumental instrumental_position = " + str(instrumental_position))
		instrumental_player.seek(instrumental_position)
		print("<After> Instrumentral playback position = " + str(instrumental_player.get_playback_position()))
		instrumental_player.get_playback_position()
		instrumental_player.stream_paused = false

	for player in acapella_players.values():
		player.seek(acapella_positions[player])
		player.stream_paused = false


func start_all() -> void:
	is_playing = true
	if instrumental_player:
		instrumental_player.seek(instrumental_position)
		instrumental_player.get_playback_position()
		instrumental_player.playing = true

	for player in acapella_players.values():
		player.playing = true


func create_voice_channel_control(character_name: String) -> void:
	var control_instance = voice_channel_control_scene.instantiate()
	control_instance.get_node("Ch_NameLbl").text = character_name
	voice_channel_container.add_child(control_instance)
	control_instance.connect("value_changed_signal", Callable(self, "on_value_changed"))


func on_value_changed(value) -> void:
	print("value changed")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		show_pause_menu()


func start_timer_before_play() -> void:
	var timer_instance = timer_scene.instantiate()
	add_child(timer_instance)
	
	timer_instance.connect("ready_to_start", Callable(self, "_on_timer_ready_to_start"))
	#_on_timer_ready_to_start()
	#play_all()

# Обработка сигнала Continue
func _on_pause_menu_continue() -> void:
	print("Continue signal received, resuming playback.")
	start_timer_before_play()


func _on_timer_ready_to_start() -> void:
	print("Timer finished, starting playback.")
	if instrumental_player.playing == false:
		start_all()
	else:
		resume_all()
