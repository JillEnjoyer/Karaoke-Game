extends HBoxContainer
class_name FolderSelector

# Сигнал отправляет полный путь выбранной (или созданной) папки
signal folder_chosen(full_path: String)

@export_enum("Franchise:1", "Album:2", "Song:3", "Version:4") var level: int = 1

@onready var options: OptionButton = $OptionButton
@onready var input_new: LineEdit = $LineEdit
@onready var create_btn: Button = $CreateBtn

var current_base_path: String = ""
var allow_creation: bool = true # Динамически задается из главного окна

func _ready() -> void:
	options.item_selected.connect(_on_item_selected)
	create_btn.pressed.connect(_on_create_pressed)
	_hide_creation_tools()

# Главная функция, которую вызывает родительская сцена
func populate(base_path: String) -> void:
	current_base_path = base_path
	options.clear()
	_hide_creation_tools()
	
	if base_path.is_empty() or not DirAccess.dir_exists_absolute(base_path):
		options.add_item("Ожидание пути...")
		options.disabled = true
		return

	options.disabled = false
	var dir = DirAccess.open(base_path)
	var dirs = dir.get_directories()

	options.add_item("Выберите папку...")
	options.set_item_disabled(0, true)

	for d in dirs:
		options.add_item(d)

	# Кнопку создания добавляем ТОЛЬКО если мы в режиме CREATE
	if allow_creation:
		options.add_separator()
		options.add_item("[+] Создать новую...")

	# --- ИСПРАВЛЕННАЯ ЛОГИКА АВТОВЫБОРА (FLOW) ---
	if dirs.size() > 0:
		# Если папки есть, выбираем ПЕРВУЮ существующую
		options.select(1)
		
		# БАГФИКС: Даем Godot один кадр на переваривание UI и только потом пускаем сигнал дальше.
		# Без этого await цепочка застревала на Альбоме, если папок было мало.
		if is_inside_tree():
			await get_tree().process_frame
			
		_on_item_selected(1)
	else:
		# Если папок нет И создание разрешено (CREATE) — переключаемся на форму создания
		if allow_creation:
			var create_idx = options.get_item_count() - 1
			options.select(create_idx)
			
			if is_inside_tree():
				await get_tree().process_frame
				
			_on_item_selected(create_idx)
		else:
			# В режиме OPEN при отсутствии папок просто оставляем заглушку активной
			options.select(0)

func _on_item_selected(idx: int) -> void:
	var text = options.get_item_text(idx)
	
	if text == "[+] Создать новую...":
		input_new.show()
		create_btn.show()
		input_new.grab_focus()
	else:
		_hide_creation_tools()
		var selected_path = current_base_path.path_join(text)
		folder_chosen.emit(selected_path)

func _on_create_pressed() -> void:
	var new_folder_name = input_new.text.strip_edges()
	if new_folder_name.is_empty():
		return
		
	var new_full_path = current_base_path.path_join(new_folder_name)
	var dir = DirAccess.open(current_base_path)
	
	if not dir.dir_exists(new_folder_name):
		dir.make_dir(new_folder_name)
		
		# Если это 3-й уровень (Песня), создаем глубокую структуру папок
		if level == 3:
			_generate_song_structure(new_full_path)
			
	input_new.text = ""
	
	# Перезаполняем этот же селектор, чтобы обновить список
	populate(current_base_path)
	
	# Ждем кадр, чтобы новые элементы отрендерились в OptionButton, и выбираем её
	if is_inside_tree():
		await get_tree().process_frame
		
	for i in range(options.get_item_count()):
		if options.get_item_text(i) == new_folder_name:
			options.select(i)
			_on_item_selected(i)
			break

func _hide_creation_tools() -> void:
	input_new.hide()
	create_btn.hide()

# Генерация полной структуры для новой песни (Уровень 3)
func _generate_song_structure(song_path: String) -> void:
	var dir = DirAccess.open(song_path)
	if dir:
		# 1. Корневая папка Audio и её подпапки
		dir.make_dir("Audio")
		var audio_path = song_path.path_join("Audio")
		var audio_dir = DirAccess.open(audio_path)
		if audio_dir:
			audio_dir.make_dir("Acapella")
			audio_dir.make_dir("Instrumental")
			
		# 2. Остальные папки проекта
		dir.make_dir("Configs")
		dir.make_dir("Subtitles")
		dir.make_dir("Video")
		
		print("[FolderSelector] Структура папок успешно развернута в: ", song_path)
