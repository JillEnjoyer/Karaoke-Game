#CatalogV2.gd
extends Control

var song_list = []  # Здесь будут храниться пути к песням
var card_size = Vector2(550, 700)
var focused_card_index = 0

var BasePath = "res://Catalog/"
var FranchisePath = ""
var SongPath = ""
var FranchiseName = ""
var SongName = ""

var ChoosenSong = ""

var return_speed = 5.0  # Скорость возвращения карточки

var Mode = "Franchise"
var TestFeature = false  # Булевая переменная для тестового режима

func _ready():
	pass

# Универсальная функция для инициализации каталога
func initial(Name: String):
	
	FranchiseName = Name
	if Name == "Franchise":
		Mode = "Franchise"
		FranchisePath = BasePath
		song_list = DirAccess.get_directories_at(BasePath)  # Получаем все папки франшиз
	else:
		Mode = "Song"
		FranchisePath = BasePath + Name
		song_list = DirAccess.get_directories_at(FranchisePath)  # Получаем все папки песен внутри франшизы
	
	#print("Список найденных папок:", song_list)
	create_cards()

func create_cards():
	for i in range(song_list.size()):
		var card = preload("res://CatalogSystem/Card.tscn").instantiate()  # Загружаем сцену карточки
		card.song_title = song_list[i]  # Название песни
		#print(BasePath + song_list[i] + "/Icon.png")
		#card.album_art = load(FranchisePath + song_list[i] + "/Icon.png")  # Картинка (если есть)
		#card.background = load(FranchisePath + song_list[i] + "/Background.png")
		
		if Mode == "Franchise":
			#print(Mode)
			#print(FranchisePath)# + song_list[i] + "/Icon.png")
			card.album_art = load(FranchisePath + song_list[i] + "/Icon.png")  # Картинка (если есть)
			card.background = load(FranchisePath + song_list[i] + "/Background.png")
		elif Mode == "Song":
			#print(Mode)
			#print(FranchisePath + song_list[i] + "/Icon.png")
			card.album_art = load(FranchisePath + "/" + song_list[i] + "/Icon.png")  # Картинка (если есть)
			card.background = load(FranchisePath + "/" + song_list[i] + "/Background.png")
		
		
		
		
		var file = FileAccess.open(FranchisePath + song_list[i] + "/About.txt", FileAccess.READ)  # Обратите внимание на слеш перед названием файла
		if file:
			var content = file.get_as_text()
			file.close()  # Не забудьте закрыть файл после использования
			
			card.about_title = content
		else:
			#print("Ошибка при открытии файла")
			pass

		#card.about_title = content
		
		card.custom_minimum_size = card_size  # Устанавливаем минимальный размер карточки
		card.pivot_offset = card_size / 2  # Центрируем точку вращения
		card.position = Vector2((i - focused_card_index) * (card_size.x * 0.75), 0)  # 75% от размера
		add_child(card)

func _input(event):
	if event.is_action_pressed("right"):
		move_focus(1)
	elif event.is_action_pressed("left"):
		move_focus(-1)
	elif event.is_action_pressed("shift"):
		# Переключаем тестовый режим
		TestFeature = not TestFeature
		update_card_positions()
	elif event.is_action_pressed("up"):
		#print(Mode)
		if Mode == "Franchise":
			main_menu()
		elif Mode == "Song":
			pass
			Catalog()
	elif event.is_action_pressed("down"):
		if Mode == "Franchise":
			SongCatalog()
		elif Mode == "Song":
			SongName = get_title_by_index(focused_card_index)
			show_song_settings(SongName)

func move_focus(direction):
	focused_card_index += direction
	focused_card_index = clamp(focused_card_index, 0, song_list.size() - 1)
	update_card_positions()

func update_card_positions():
	var center_x = get_viewport().size.x / 2  # Центр экрана по оси X
	var center_y = get_viewport().size.y / 2  # Центр экрана по оси Y
	var base_spacing = card_size.x * 0.8  # Стандартное расстояние
	var spacing_factor = 0.8  # Коэффициент уменьшения расстояния

	# Объявляем переменные вне if/else блока
	var target_scale = 1.0
	var offset_x = 0.0
	var offset_y = 0.0

	for i in range(song_list.size()):
		var card = get_child(i)
		var distance_from_center = abs(i - focused_card_index)

		# Рассчитываем позицию и масштаб для тестового режима или стандартного
		if TestFeature:
			# В тестовом режиме: формируем "колизей"
			target_scale = 1.0 - distance_from_center * 0.25
			target_scale = clamp(target_scale, 0.5, 1.0)
			offset_x = sign(i - focused_card_index) * base_spacing * pow(spacing_factor, distance_from_center)
			offset_y = distance_from_center * (card_size.y * 0.2)
		else:
			# Обычный режим
			target_scale = 1.0 if i == focused_card_index else 0.8
			offset_x = (i - focused_card_index) * base_spacing
			offset_y = 0  # В обычном режиме Y не смещается

		var target_position = Vector2(center_x + offset_x - card_size.x / 2, center_y - offset_y - card_size.y / 2)
		
		# Анимация перемещения и изменения масштаба
		var tween = get_tree().create_tween()
		tween.tween_property(card, "position", target_position, 0.3)
		tween.tween_property(card, "scale", Vector2(target_scale, target_scale), 0.3)
		
		# Z-buffer: чем ближе к центру, тем выше Z-index
		card.z_index = -distance_from_center

func load_scene(scene_path: String, initial_value: String = ""):
	var new_scene = load(scene_path).instantiate()
	if new_scene:
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.queue_free()  # Удаляем текущую сцену
			
			get_tree().root.add_child(new_scene)
			get_tree().set_current_scene(new_scene)  # Устанавливаем новую сцену
			
			if initial_value != "":
				new_scene.initial(initial_value)  # Передаем значение, если оно не пустое
				print("Название карточки:", initial_value)
		else:
			print("Ошибка: не удалось загрузить текущую сцену!")
	else:
		print("Ошибка: не удалось загрузить сцену по пути: ", scene_path)

# Пример использования для различных сцен:
func SongCatalog():
	var title = get_title_by_index(focused_card_index)
	load_scene("res://CatalogSystem/Catalog.tscn", title)

func Catalog():
	load_scene("res://CatalogSystem/Catalog.tscn", "Franchise")

# Возвращение в главное меню
func main_menu():
	load_scene("res://Scenes/MainMenu.tscn")

func get_title_by_index(index: int) -> String:
	if index >= 0 and index < song_list.size():
		return song_list[index]  # Возвращаем название по индексу
	return ""  # Если индекс вне диапазона, возвращаем пустую строку

func show_song_settings(song_name: String):
	var settings_panel = preload("res://Presetting.tscn").instantiate()
	add_child(settings_panel)
	settings_panel.CollectNames(FranchiseName, SongName)
