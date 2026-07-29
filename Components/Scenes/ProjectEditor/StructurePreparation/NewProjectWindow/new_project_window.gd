extends Control

signal project_created(project_path: String)
signal project_opened(project_path: String)

var current_mode: GlobalEnums.EditorWindowMode = GlobalEnums.EditorWindowMode.OPEN

@onready var franchise_selector = $Panel/BlockMenu/FranchiseSelector
@onready var album_selector = $Panel/BlockMenu/AlbumSelector
@onready var song_selector = $Panel/BlockMenu/SongSelector
@onready var version_selector = $Panel/BlockMenu/VersionSelector

@onready var action_button = $Panel/ActionBtn 

var final_song_path: String = ""
var final_config_name: String = ""


func init_window(mode: GlobalEnums.EditorWindowMode) -> void:
	current_mode = mode 

func _ready() -> void:
	await get_tree().process_frame
	
	franchise_selector.level = 1
	album_selector.level = 2
	song_selector.level = 3
	
	var can_create = (current_mode == GlobalEnums.EditorWindowMode.CREATE)
	franchise_selector.allow_creation = can_create
	album_selector.allow_creation = can_create
	song_selector.allow_creation = can_create
	
	version_selector.allow_creation = false
	version_selector.hide()
	
	if current_mode == GlobalEnums.EditorWindowMode.CREATE:
		action_button.text = "Create New Project"
	else:
		action_button.text = "Open Existing Project"
		
	action_button.disabled = true
	
	franchise_selector.folder_chosen.connect(_on_franchise_chosen)
	album_selector.folder_chosen.connect(_on_album_chosen)
	song_selector.folder_chosen.connect(_on_song_chosen)
	
	version_selector.folder_chosen.connect(_on_version_chosen)
	
	var base_catalog = PreferencesData.get_data("catalog_path")
	franchise_selector.populate(base_catalog)
	
	album_selector.populate("")
	song_selector.populate("")


func _on_franchise_chosen(path: String) -> void:
	if path.is_empty() or path.ends_with("Choose folder..."):
		album_selector.populate("")
		song_selector.populate("")
		version_selector.hide()
		action_button.disabled = true
		return
		
	album_selector.populate(path)
	song_selector.populate("")
	version_selector.hide()
	action_button.disabled = true

func _on_album_chosen(path: String) -> void:
	if path.is_empty() or path.ends_with("Choose folder..."):
		song_selector.populate("")
		version_selector.hide()
		action_button.disabled = true
		return
		
	song_selector.populate(path)
	version_selector.hide()
	action_button.disabled = true

func _on_song_chosen(path: String) -> void:
	if path.is_empty() or path.ends_with("Choose folder..."):
		final_song_path = ""
		version_selector.hide()
		action_button.disabled = true
		return
		
	final_song_path = path
	
	# Если мы в режиме СОЗДАНИЯ, нам не нужно выбирать версию
	if current_mode == GlobalEnums.EditorWindowMode.CREATE:
		version_selector.hide()
		final_config_name = ""
		action_button.disabled = false
		print("[Window] Режим CREATE. Путь песни готов: ", final_song_path)
	
	# Если мы в режиме ОТКРЫТИЯ, сканируем папку Configs
	else:
		action_button.disabled = true # Кнопка заблокирована, пока не выберут версию!
		var configs_path = final_song_path.path_join("Configs")
		
		# Заставляем наш селектор версий отсканировать файлы вместо папок
		_populate_version_selector(configs_path)


func _populate_version_selector(configs_path: String) -> void:
	version_selector.current_base_path = configs_path
	version_selector.options.clear()
	version_selector._hide_creation_tools()
	
	if not DirAccess.dir_exists_absolute(configs_path):
		version_selector.options.add_item("Папка Configs не найдена")
		version_selector.options.disabled = true
		version_selector.show()
		return
		
	version_selector.options.disabled = false
	var dir = DirAccess.open(configs_path)
	
	# Считываем ФАЙЛЫ вместо директорий
	var files = dir.get_files()
	var json_configs: Array[String] = []
	
	# Фильтруем только файлы конфигураций .json
	for f in files:
		if f.ends_with(".json"):
			json_configs.append(f)
			
	version_selector.options.add_item("Choose project version...")
	version_selector.options.set_item_disabled(0, true)
	
	for cfg in json_configs:
		version_selector.options.add_item(cfg)
		
	version_selector.show() # Делаем селектор видимым для пользователя
	
	# Автовыбор версии, если они существуют
	if json_configs.size() > 0:
		version_selector.options.select(1)
		if is_inside_tree():
			await get_tree().process_frame
		# Симулируем выбор первой версии
		_on_version_chosen(configs_path.path_join(json_configs[0]))
	else:
		version_selector.options.select(0)
		final_config_name = ""


func _on_version_chosen(full_file_path: String) -> void:
	if full_file_path.is_empty() or full_file_path.ends_with("Choose project version..."):
		final_config_name = ""
		action_button.disabled = true
		return
		
	# Извлекаем чистое имя файла (например, "version_1.json")
	final_config_name = full_file_path.get_file()
	action_button.disabled = false
	print("[Window] Config version choosen: ", final_config_name)


# --- ФИНАЛЬНОЕ ДЕЙСТВИЕ ---

func _on_action_btn_pressed() -> void:
	# Формируем пакет данных для отправки в Editor
	var project_pack = {
		"song_path": final_song_path,
		"config_name": final_config_name,
		"editor_mode": "CREATE" if current_mode == GlobalEnums.EditorWindowMode.CREATE else "OPEN"
	}
	
	if current_mode == GlobalEnums.EditorWindowMode.CREATE:
		# Передаем управление событию создания
		project_created.emit(project_pack)
	else:
		# Передаем управление событию открытия
		project_opened.emit(project_pack)
		
	queue_free()

func _create_project_meta(path: String) -> void:
	# Оповещаем редактор, что проект создан
	project_created.emit(path)
	print("[Window] Сигнал project_created отправлен для: ", path)

func _load_existing_project(path: String) -> void:
	# Оповещаем редактор, что проект открыт
	project_opened.emit(path)
	print("[Window] Сигнал project_opened отправлен для: ", path)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		print("escape")
		queue_free()
