extends Control

@onready var ModeCheckBox = $ModeCheckBox
@onready var AcapellaCheckBox = $AcapellaCheckBox
@onready var NameLbl = $SongNameLbl
@onready var SongIcon = $SongIcon

var EndPath = ""
var Franchise = ""
var Song = ""
var Acapella = ""
var FolderData = {}

var log = Core.get_node("Debugger")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_back_btn_pressed() -> void:
	self.queue_free()

func _on_start_btn_pressed() -> void:
	# Проверяем, какие варианты чекбоксов выбраны
	var selected_mode = ModeCheckBox.text if ModeCheckBox else ""  # Здесь можно расширить логику, если будет несколько режимов
	var selected_acapella = AcapellaCheckBox.text if AcapellaCheckBox else "" #.is_checked()

	# Вызываем плеер и передаем нужные данные
	if selected_acapella != "":
		start_karaoke(Franchise, Song, selected_acapella, selected_mode)
	else:
		print("Выберите акапеллу перед запуском!")

func CollectNames(FranchiseName: String, SongName: String):
	Franchise = FranchiseName
	log.debug("Presetting.gd", "CollectNames()", "FrPath = " + Franchise)
	Song = SongName
	log.debug("Presetting.gd", "CollectNames()", "SnName = " + Song)
	Init()

func Init():
	ScanFolder()
	ModeCheckBox.text = "Стандартный"  # Устанавливаем текст режима игры
	AcapellaCheckBox.clear()  # Очищаем предыдущие элементы в CheckBox

	# Добавляем папки в AcapellaCheckBox
	for folder_name in FolderData.keys():
		AcapellaCheckBox.add_item(folder_name)  # Добавляем каждую папку как элемент

func ScanFolder():
	# Путь к папке для сканирования
	var path = Franchise + "/" + Song + "/Audio"
	print("Путь = " + path)
	FolderData = {}  # Очищаем предыдущие данные

	# Открываем директорию
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()  # Начинаем перечисление содержимого директории
		var folder_name = dir.get_next()  # Получаем первый элемент
		
		while folder_name != "":
			if dir.current_is_dir():  # Проверяем, что это папка
				FolderData[folder_name] = true  # Добавляем имя папки в FolderData
			folder_name = dir.get_next()  # Переходим к следующему элементу
		
		dir.list_dir_end()  # Завершаем перечисление
	else:
		print("Не удалось открыть папку: ", path)

	print(FolderData)  # Выводим найденные папки

func start_karaoke(franchise: String, song: String, acapella: String, mode: String) -> void:
	# Здесь будет логика запуска караоке с передачей данных
	print("Запуск караоке с данными:")
	print("Франшиза: ", franchise)
	print("Песня: ", song)
	print("Акапелла: ", acapella)
	print("Режим: ", mode)
	var PlayerScene = load("res://PlayerScene/PlayerScene/PlayerScene.tscn").instantiate()
	#self.queue_free()
	
	var root = get_tree().root # Получаем корневой узел (весь Viewport)
	
	# Перебираем всех детей корневого узла
	for child in root.get_children():
		if child != Core: # Если узел не является глобальным
			child.queue_free() # Удаляем его
	
	get_tree().root.add_child(PlayerScene)
	get_tree().set_current_scene(PlayerScene)  # Устанавливаем новую сцену
	PlayerScene.init(franchise, song, acapella, mode)
