# text_voice_comparer.gd
extends Control

## Panels
@onready var input_text_edit = $SplitContainer/InputPanel/TextEdit
@onready var output_json_visualizer = $SplitContainer/OutputPanel/JsonVisualizer
@onready var path_text = $SplitContainer/InputPanel/HBoxContainer/FMHBox/RichTextLabel
@onready var data_lbl = $SplitContainer/InputPanel/HBoxContainer/FMHBox/DataLbl
@onready var tcp_client = $TextVoiceTCPClient

## Buttons
@onready var vosk_base_btn_load = $SplitContainer/InputPanel/RegisterHBox/VoskBaseBtnLoad
@onready var vosk_base_btn_save = $SplitContainer/InputPanel/RegisterHBox/VoskBaseBtnSave
@onready var vosk_output_btn_load = $SplitContainer/InputPanel/RegisterHBox/VoskOutputBtnLoad
@onready var vosk_output_btn_save = $SplitContainer/InputPanel/RegisterHBox/VoskOutputBtnSave

@onready var export_subtitles_btn = $SplitContainer/InputPanel/HBoxContainer/ExportSubtitlesBtn

# Add/Remove Character
@onready var character_option_button = $SplitContainer/InputPanel/RegisterHBox/CharacterHbox/OptionButton
@onready var add_char_btn = $SplitContainer/InputPanel/RegisterHBox/CharacterHbox/VBoxContainer/AddBtn
@onready var remove_char_btn = $SplitContainer/InputPanel/RegisterHBox/CharacterHbox/VBoxContainer/RemoveBtn
# Массив для хранения зарегистрированных персонажей
var available_characters: Array[String] = ["all"]


const WhisperNTextComparisorLocal = preload("res://Components/Scenes/Whisper2TextComparisor/whisper_n_text_comparisor.gd")

# Data Backups
var cached_raw_whisper_result: Array = []   
var current_aligned_result: Array = []

var ffmpeg_path := PreferencesData.get_ext_path("ffmpeg")
var whisper_model_dir := PreferencesData.get_ext_path("WhisperModelDir")
var whisper_model_name := "turbo"

var user_reference_text: String = ""
var whisper_recognized_text: String = ""
var target_track_wrapper: Node = null



func import_song_path(path: String) -> void:
	#get_tree().process_frame
	Debugger.debug("Choosen file: " + path)
	if path:
		path_text.text = path
		return
	var error = "No files chosen"
	Debugger.warning(error)
	path_text.text = error

	await get_tree().create_timer(3.0).timeout
	self.queue_free()


func _ready() -> void:
	VocatoolWatchdog.tool_ready.connect(tcp_client._on_tool_ready)
	# FFmpeg не нужен, шлем пустышку
	tcp_client.launch_worker(ffmpeg_path)
	
	# Подключаем сигналы от нового воркера
	tcp_client.whisper_result_ready.connect(_on_process_finished)
	tcp_client.download_progress_updated.connect(_on_download_progress)
	#tcp_client.status_message.connect(_on_status_message)
	
	export_subtitles_btn.pressed.connect(_on_export_subtitles_pressed)
	_update_character_ui()
	add_char_btn.pressed.connect(_on_add_character_pressed)
	remove_char_btn.pressed.connect(_on_remove_character_pressed)
	
	# Твои кнопки Load/Save
	vosk_base_btn_load.pressed.connect(_on_vosk_base_btn_load_pressed)
	vosk_base_btn_save.pressed.connect(_on_vosk_base_btn_save_pressed)
	vosk_output_btn_load.pressed.connect(_on_vosk_output_btn_load_pressed)
	vosk_output_btn_save.pressed.connect(_on_vosk_output_btn_save_pressed)


func _on_download_progress(percent: float, text: String) -> void:
	# Выводим в поле пути файла (или можешь добавить ProgressBar в сцену и менять его value)
	data_lbl.text = "Скачивание модели: " + str(percent) + "% (" + text + ")"


func _on_status_message(msg: String) -> void:
	data_lbl.text = msg


# Кнопка СЕЙВ сырого результата (если пользователю зачем-то нужно сбросить выравнивание обратно к сырому)
func _on_vosk_base_btn_save_pressed() -> void:
	# Если в UI что-то отображается, мы можем сохранить это как сырой бэкап
	var current_ui_data = output_json_visualizer.get_final_json()
	if not current_ui_data.is_empty():
		cached_raw_whisper_result = current_ui_data
		Debugger.info("Текущее состояние интерфейса сохранено в кэш СЫРОГО Vosk.")
	else:
		Debugger.warning("Нечего сохранять, визуализатор пуст.")

# Кнопка ЛОАД сырого результата
func _on_vosk_base_btn_load_pressed() -> void:
	if not cached_raw_whisper_result.is_empty():
		output_json_visualizer.visualize(cached_raw_whisper_result)
		Debugger.info("Сырой результат Vosk успешно загружен в интерфейс.")
	else:
		Debugger.warning("Кэш сырого Vosk пуст. Нечего загружать.")


# ==============================================================================
# БЛОК КНОПОК: ВЫРОВНЕННЫЙ/ИТОГОВЫЙ РЕЗУЛЬТАТ (Правя пара кнопок)
# ==============================================================================

# Кнопка СЕЙВ выровненного текста (Запоминаем текущую работу пользователя)
func _on_vosk_output_btn_save_pressed() -> void:
	# КРИТИЧЕСКИ ВАЖНО: Забираем измененные пользователем данные прямо из UI!
	var current_ui_data = output_json_visualizer.get_final_json()
	
	if not current_ui_data.is_empty():
		current_aligned_result = current_ui_data
		Debugger.info("Прогресс редактирования успешно сохранен в память.")
	else:
		Debugger.warning("Визуализатор пуст. Сохранение отменено.")

# Кнопка ЛОАД выровненного текста (Восстанавливаем сохраненный прогресс)
func _on_vosk_output_btn_load_pressed() -> void:
	if not current_aligned_result.is_empty():
		output_json_visualizer.visualize(current_aligned_result)
		Debugger.info("Сохраненный прогресс успешно восстановлен в интерфейсе.")
	else:
		Debugger.warning("Архив выровненного результата пуст. Нечего загружать.")
	

# Обновление выпадающего списка
func _update_character_ui() -> void:
	character_option_button.clear()
	for character in available_characters:
		character_option_button.add_item(character)
	
	# Автоматически передаем обновленный список персонажей в визуализатор,
	# чтобы JsonRowV2 мог обновить свои внутренние выпадающие списки строк!
	if output_json_visualizer.has_method("set_available_characters"):
		output_json_visualizer.set_available_characters(available_characters)


func _on_add_character_pressed() -> void:
	# Создаем быстрое всплывающее диалоговое окно для ввода имени
	var dialog = ConfirmationDialog.new()
	dialog.title = "Добавить персонажа"
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Введите имя персонажа..."
	dialog.add_child(line_edit)
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 100))
	
	dialog.confirmed.connect(func():
		var new_name = line_edit.text.strip_edges()
		if new_name != "" and not available_characters.has(new_name):
			available_characters.append(new_name)
			_update_character_ui()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())


func _on_remove_character_pressed() -> void:
	var selected_idx = character_option_button.selected
	if selected_idx == -1: return
	
	var char_name = character_option_button.get_item_text(selected_idx)
	
	# Запрещаем удалять дефолтного персонажа "all"
	if char_name == "all":
		Debugger.warning("Нельзя удалить базового персонажа 'all'")
		return
		
	available_characters.remove_at(selected_idx)
	_update_character_ui()


func import_text_data_from_controller(user_text: String, whisper_text: String) -> void:
	user_reference_text = user_text
	whisper_recognized_text = whisper_text

func _on_button_pressed() -> void:
	var file_picker = FilePicker.new()
	files_selected(file_picker.open_file_picker())

func files_selected(paths: PackedStringArray):
	Debugger.debug("Choosen files: " + str(paths))
	if paths.size() > 0:
		var file_path := paths[0]
		data_lbl.text = file_path
		return
	var error = "No files chosen"
	Debugger.warning(error)
	data_lbl.text = error


# Метод инициализации окна из главного таймлайна программы
func init_handler(track_node: Node) -> void:
	target_track_wrapper = track_node
	Debugger.info("[VoskUI] Инцициализирован для трека: " + track_node.name)


func _on_start_btn_pressed() -> void:
	if data_lbl.text != "" and not data_lbl.text.begins_with("Скачивание"):
		var global_audio_path = ProjectSettings.globalize_path(path_text.text)
		# ТЕПЕРЬ ПЕРЕДАЕМ ДИРЕКТОРИЮ И ИМЯ
		tcp_client.process_audio_file(global_audio_path, whisper_model_dir, whisper_model_name)
		data_lbl.text = "AI initializing..."


func _on_process_finished(result: Array):
	Debugger.info("Whisper закончил работу! Начинаем обработку...")
	cached_raw_whisper_result = result
	output_json_visualizer.visualize(result)
	data_lbl.text = "Ready!"

"""
func save_current_visualizer_state_as_backup() -> void:
	# Метод забирает из UI текущее состояние строк (даже если юзер правил их руками)
	var current_ui_data = output_json_visualizer.get_final_json()
	current_aligned_result = current_ui_data
	Debugger.info("Текущее состояние строк сохранено в промежуточную переменную проекта.")


# Кнопка «Загрузить бэкап распознавания» (VoskResultLoad)
func load_backup_to_visualizer() -> void:
	if not current_aligned_result.is_empty():
		output_json_visualizer.visualize(current_aligned_result)
		Debugger.info("Backup successfully returned.")
"""

# КНОПКА ЭКСПОРТА (ExportSubtitles)
func _on_export_subtitles_pressed() -> void:
	var final_subtitles_array = output_json_visualizer.get_final_json() 
	if final_subtitles_array.is_empty():
		Debugger.warning("Нечего экспортировать, визуализатор пуст!")
		return
		
	if is_instance_valid(target_track_wrapper):
		target_track_wrapper.receive_generated_subtitles(final_subtitles_array, available_characters)
		Debugger.info("Субтитры успешно импортированы!")
	else:
		Debugger.error("Целевой трек не найден!")

	queue_free()


func _exit_tree():
	VocatoolWatchdog.terminate_tool("whisper_handler")


func _on_comparisor_btn_pressed() -> void:
	var user_text = input_text_edit.text.strip_edges()
	
	if user_text.length() < 25:
		output_json_visualizer.visualize(cached_raw_whisper_result)
	else:
		Debugger.info("Обнаружен эталонный текст. Запускаем умное выравнивание таймингов...")
		# Обращаемся к обновленному компаратору
		var aligned_data = WhisperNTextComparisorLocal.align_text_with_whisper(user_text, cached_raw_whisper_result)

		current_aligned_result = aligned_data
		output_json_visualizer.visualize(aligned_data)
