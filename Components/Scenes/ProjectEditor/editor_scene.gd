extends Control

@onready var timeline = $Timeline
@onready var media_pool = $MediaPool
@onready var media_player = $MediaPlayer

var last_exported_config: Dictionary = {}
var is_dirty: bool = false

var current_project_path: String = ""


func _ready() -> void:
	media_player.editor_preinit()
	
	if timeline.has_signal("timeline_changed"):
		timeline.timeline_changed.connect(_on_timeline_changed)
	
	#media_pool.update_file_list()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		toggle_playback()
	if Input.is_action_just_pressed("pause"):
		leave_scene()
	
	
	
	#if event is InputEventMouseButton:
	#	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
	#		print("LMC detected!")


func toggle_playback() -> void:
	if media_player.is_playing():
		media_player.pause()
		return

	var current_config = timeline.export_project_configs()
	
	if _check_needs_hard_reinit(current_config):
		Debugger.debug("HARD RE-INIT: File list changed. Reloading resources...")
		#media_player.hard_reinit(current_config)
		is_dirty = false
	elif is_dirty:
		Debugger.debug("SOFT RE-INIT: Same files, Updating jumpers...")
		media_player.soft_reinit(current_config)
		is_dirty = false
	
	last_exported_config = current_config
	
	var start_pos_px = timeline.time_pointer.position.x
	var start_time = start_pos_px / timeline.px_to_sec_ratio
	
	media_player.play_from(start_time)


func _check_needs_hard_reinit(new_config: Dictionary) -> bool:
	if last_exported_config.is_empty():
		return true
		
	var old_files = _get_file_paths_list(last_exported_config)
	var new_files = _get_file_paths_list(new_config)
	
	return old_files != new_files


func _get_file_paths_list(config: Dictionary) -> Array:
	var paths = []
	var files = config.get("files", {})
	
	for category in ["acapella", "instrumental"]:
		var cat_dict = files.get(category, {})
		for key in cat_dict:
			paths.append(cat_dict[key].get("path", ""))
			
	if files.has("video"):
		paths.append(files["video"].get("path", ""))
		
	paths.sort()
	return paths


func _on_timeline_changed() -> void:
	is_dirty = true

func switch_player_scene_mode() -> void:
	pass


func _on_fm_btn_pressed() -> void:
	Debugger.debug("FM is opened")
	open_fm("all")

func open_fm(type: String) -> void:
	var file_picker = FilePicker.new()
	files_selected(file_picker.open_file_picker())


func files_selected(paths: PackedStringArray):
	Debugger.debug("Chosen files: " + str(paths))
	media_pool.add_files(paths)


func _on_new_project_btn_pressed() -> void:
	var win = UIManager.show_ui("NewProjectWindow", self)
	if win:
		win.init_window(GlobalEnums.EditorWindowMode.CREATE)
		if not win.project_created.is_connected(_on_project_folder_selected):
			win.project_created.connect(_on_project_folder_selected)


func _on_open_existing_btn_pressed() -> void:
	var win = UIManager.show_ui("NewProjectWindow", self)
	if win:
		win.init_window(GlobalEnums.EditorWindowMode.OPEN)
		if not win.project_opened.is_connected(_on_project_folder_selected):
			win.project_opened.connect(_on_project_folder_selected)


# Этот метод принимает словарь c данными проекта от NewProjectWindow
func _on_project_folder_selected(project_pack: Dictionary) -> void:
	# Вытаскиваем путь к папке песни из переданного словаря
	current_project_path = project_pack.get("song_path", "")
	
	if current_project_path.is_empty():
		push_error("Получен пустой путь к проекту!")
		return
		
	Debugger.debug("Проект успешно инициализирован. Путь: " + current_project_path)
	
	# Опционально: здесь можно вытащить имя конфига, если проект ОТКРЫВАЕТСЯ
	var config_name = project_pack.get("config_name", "")
	var mode = project_pack.get("editor_mode", "OPEN")
	
	if mode == "OPEN" and not config_name.is_empty():
		Debugger.debug("Нужно загрузить существующий конфиг: " + config_name)
		# Тут в будущем будет твоя логика загрузки сохраненного JSON на таймлайн



func _on_export_btn_pressed() -> void:
	if current_project_path.is_empty():
		push_error("Не установлен путь текущего проекта! (current_project_path пуст)")
		return

	var all_wrappers = timeline.get_all_wrappers() 
	var export_items_info: Array = []
	
	for wrapper in all_wrappers:
		# Обращаемся напрямую к переменным ControllerWrapper
		var media_type = wrapper.node_type
		var file_path = wrapper.initial_path
		var file_name = file_path.get_file()
		var node_name = wrapper.node_name # Здесь хранится Роль/Инструмент/ID
		
		# Формируем красивое описание для интерфейса на основе типа
		var display_text = ""
		match media_type:
			"acapella": display_text = "Acapella (%s): %s" % [node_name, file_name]
			"instrumental", "bass", "drums": display_text = "Instrumental (%s): %s" % [node_name, file_name]
			"video": display_text = "Video (%s): %s" % [node_name, file_name]
			_: display_text = "File: %s" % file_name
		
		export_items_info.append({
			"wrapper": wrapper,
			"display_text": display_text,
			"media_type": media_type
		})
	
	var window = UIManager.get_desired_node("ExportWindow").instantiate()
	if not window:
		push_error("Не удалось получить ExportWindow из UIManager")
		return
		
	# Инициализируем окно (передаем информацию о треках)
	window.init_window(export_items_info)
	
	if window.export_files.is_connected(_on_export_confirmed):
		window.export_files.disconnect(_on_export_confirmed)
	window.export_files.connect(_on_export_confirmed)
	
	add_child(window)


func _on_export_confirmed(export_data: Dictionary) -> void:
	var project_name = export_data["project_name"]
	var language = export_data["language"]
	var selected_items = export_data["wrappers"] # Здесь у нас массив элементов из ExportWindow
	
	var version_tag = "[%s][%s]" % [project_name, language]
	print("--- НАЧАЛО ЭКСПОРТА ВЕРСИИ: %s ---" % version_tag)
	
	var main_config = {
		"files": {
			"acapella": {},
			"instrumental": {},
			"video": {
				"videos": {},
				"segments": []
			}
		},
		"characters": []
	}
	
	var subtitles_config_data = [] 
	
	# Получаем ОРИГИНАЛЬНЫЕ живые треки с таймлайна
	var timeline_wrappers = timeline.get_all_wrappers()
	
	for wrapper in timeline_wrappers:
		if not is_instance_valid(wrapper): continue
		
		# Проверяем, выбрал ли пользователь этот трек в ExportWindow.
		# Мы ищем совпадение по initial_path (исходному пути файла)
		var is_selected = false
		for item in selected_items:
			# Если в окне экспорта лежит сам wrapper или словарь с путем, проверяем его
			var item_path = item.initial_path if typeof(item) == TYPE_OBJECT else item.get("initial_path", "")
			if item_path == wrapper.initial_path:
				is_selected = true
				break
				
		# Если пользователь снял галочку с этого файла — игнорируем его
		if not is_selected:
			print("Пропуск файла (галочка снята): ", wrapper.initial_path.get_file())
			continue
			
		# Вызываем экспорт у ОРИГИНАЛЬНОГО трека с таймлайна
		var wrapper_data = wrapper.export() 
		var media_type = wrapper_data.get("node_type", "")
		var original_file_path = wrapper_data.get("initial_path", "")
		var node_name = wrapper_data.get("node_name", "")
		

		# Если имя пустое — берем имя файла БЕЗ расширения
		if node_name.is_empty():
			node_name = original_file_path.get_file().get_basename()
		else:
			# Если в имени уже торчит расширение (жертва прошлых багов), счищаем его
			node_name = node_name.get_basename()


		# Если вдруг данные пустые, выводим ошибку в консоль для отладки
		if original_file_path.is_empty() or node_name.is_empty():
			push_error("Критическая ошибка: Трек на таймлайне имеет пустой путь или имя! Тип: " + media_type)
			continue
		
		var target_dir = ""
		var file_name = ""
		var relative_path = ""
		
		match media_type:
			"acapella":
				if not node_name in main_config["characters"]:
					main_config["characters"].append(node_name)
				
				target_dir = current_project_path.path_join("Audio/Acapella").path_join(version_tag)
				file_name = "all." + original_file_path.get_extension() if node_name.to_lower() == "all" else node_name + "." + original_file_path.get_extension()
				relative_path = "Audio/Acapella/%s/%s" % [version_tag, file_name]
				
				if wrapper_data.has("subtitles") and typeof(wrapper_data["subtitles"]) == TYPE_ARRAY:
					subtitles_config_data.append_array(wrapper_data["subtitles"])
					Debugger.debug("что-то было добавлено в субтитры: " + str(wrapper_data["subtitles"]))
				else:
					Debugger.debug("У трека %s нет субтитров для добавления" % node_name)
				
				var clean_data = {
					"path": relative_path,
					"segments": wrapper_data.get("segments", [])
				}
				main_config["files"]["acapella"][node_name] = clean_data
				
			"instrumental", "bass", "drums", "instruments":
				target_dir = current_project_path.path_join("Audio/Instrumental/Original")
				file_name = node_name.to_lower() + "." + original_file_path.get_extension()
				relative_path = "Audio/Instrumental/Original/%s" % file_name
				
				var clean_data = {
					"path": relative_path,
					"segments": wrapper_data.get("segments", [])
				}
				main_config["files"]["instrumental"][node_name] = clean_data
				
			"video":
				target_dir = current_project_path.path_join("Video")
				file_name = node_name + "." + original_file_path.get_extension()
				relative_path = "Video/%s" % file_name
				
				main_config["files"]["video"]["videos"][node_name] = {"path": relative_path}
				
				for seg in wrapper_data.get("segments", []):
					var clean_seg = {
						"id": node_name,
						"start": seg.get("start", 0.0),
						"end": seg.get("end", null)
					}
					main_config["files"]["video"]["segments"].append(clean_seg)
						
		# Физически копируем файл
		_copy_media_file(original_file_path, target_dir, file_name)

	# 1. Сохраняем главный конфиг JSON
	var main_config_path = current_project_path.path_join("Configs").path_join(version_tag + ".json")
	_save_json_file(main_config_path, main_config)
	print("Главный конфиг успешно сохранен: ", main_config_path)

	# 2. Сохраняем субтитры (только если они есть)
	if not subtitles_config_data.is_empty():
		var subs_path = current_project_path.path_join("Subtitles/[PREPARED]").path_join(version_tag + ".json")
		_save_json_file(subs_path, subtitles_config_data)
		print("Субтитры успешно сохранены: ", subs_path)

	# =========================================================================
	# 3. АВТОГЕНЕРАЦИЯ КОРНЕВОГО config.json ДЛЯ КАТАЛОГА ИГРЫ
	# =========================================================================
	var root_config_path = current_project_path.path_join("config.json")
	var root_config = {}

	# Если файл уже существует, прочитаем его, чтобы не затереть автора или старые хайлайты
	if FileAccess.file_exists(root_config_path):
		var file = FileAccess.open(root_config_path, FileAccess.READ)
		if file:
			var test_json = JSON.parse_string(file.get_as_text())
			if typeof(test_json) == TYPE_DICTIONARY:
				root_config = test_json
			file.close()

	# Если файл новый, заполняем базовые дефолтные поля
	if root_config.is_empty():
		root_config = {
			"created_by": project_name, # По дефолту пишем имя проекта, пользователь сможет изменить в блокноте
			"prepared_by": "76561198375439242", # Твой фиксированный ID создателя
			"config_version": "0.0.1",
			"shuffle_highlights": true,
			"highlights": []
		}

	# Автоматически проверяем хайлайты. Если массив пустой, сгенерируем один базовый 
	# на основе текущей экспортируемой версии (например, с 30 по 60 секунду песни),
	# чтобы игра точно подцепила превью и не вылетала из-за пустого массива.
	if not root_config.has("highlights") or typeof(root_config["highlights"]) != TYPE_ARRAY or root_config["highlights"].is_empty():
		root_config["highlights"] = [
			{
				"version": version_tag, # Текущий тег, например "[MyCoolProject][ENG]"
				"logical_start": 30.0,  # Дефолтное начало превью
				"logical_end": 60.0,    # Дефолтный конец превью
				"repeat": true
			}
		]
	else:
		# Если хайлайты уже были, но мы экспортируем новую версию, проверим, 
		# привязаны ли они к какой-то версии. Если там старый тег, обновим его или убедимся, что структура верна.
		for highlight in root_config["highlights"]:
			if typeof(highlight) == TYPE_DICTIONARY and highlight.get("version", "").is_empty():
				highlight["version"] = version_tag

	# Сохраняем config.json прямо в корень папки проекта
	_save_json_file(root_config_path, root_config)
	print("Корневой config.json для игрового каталога успешно обновлен/создан: ", root_config_path)


# Вспомогательные методы сохранения и копирования файлов
func _copy_media_file(source_path: String, target_dir: String, file_name: String) -> void:
	if not FileAccess.file_exists(source_path):
		push_error("Исходный файл не найден: " + source_path)
		return
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_recursive_absolute(target_dir)
		
	var target_path = target_dir.path_join(file_name)
	if source_path == target_path:
		return
		
	var err = DirAccess.copy_absolute(source_path, target_path)
	if err != OK:
		push_error("Ошибка копирования: %s -> %s" % [source_path, target_path])

func _save_json_file(path: String, data: Variant) -> void:
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))



func leave_scene():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure? All unsaved changes will be lost!"
	dialog.title = "Quit confirmation"
	dialog.get_ok_button().text = "Yes"
	dialog.connect("confirmed", Callable(self, "_on_yes_pressed"))

	self.add_child(dialog)
	dialog.popup_centered()
func _on_yes_pressed():
	UIManager.cleanup_tree()
	UIManager.show_ui("MainMenu")
