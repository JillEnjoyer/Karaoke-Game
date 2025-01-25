extends Control

var card_size = Vector2(550, 700)
var focused_card_index = 0

var base_path = Core.get_node("PreferencesData").getData("catalog_path")
var current_path = base_path
var path_stack = []

var song_list = []

var return_speed = 5.0  # Card Returning speed

var TestFeature: bool = false

func _ready():
	load_cards_at_path(current_path)


func load_cards_at_path(path: String):
	clear_cards()  # Удаляем старые карточки
	song_list.clear()
	var dir_access = DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path + "/" + file_name
				if DirAccess.open(full_path):
					song_list.append(file_name)  # Добавляем папку в список
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
	
	create_cards()
	move_focus(-1)


func create_cards():
	for i in range(song_list.size()):
		var card = create_card(song_list[i], i)
		add_child(card)


func create_card(song_name: String, index: int) -> Control:
	var card = preload("res://CatalogSystem/Card/Card.tscn").instantiate()
	card.song_title = song_name

	var icon_path = current_path + "/" + song_name + "/Icon.png"
	var bg_path = current_path + "/" + song_name + "/Background.png"
	
	#print("Загружаемый путь:", icon_path)
	
	card.album_art = load_texture_or_placeholder(icon_path)
	card.background = load_texture_or_placeholder(bg_path)

	card.custom_minimum_size = card_size
	card.pivot_offset = card_size / 2
	card.position = Vector2((index - focused_card_index) * (card_size.x * 0.75), 0)
	
	return card


func load_texture_or_placeholder(file_path: String) -> Texture2D:
	var texture = load_texture(file_path)
	if texture == null:
		#print("Using placeholder for missing texture:", file_path)
		return preload("res://icon.svg")  # Путь к заглушке
	return texture


func load_texture(file_path: String):
	var image = ImageTexture.new()
	if FileAccess.file_exists(file_path):
		var img = Image.new()
		if img.load(file_path) == OK:
			return (image.create_from_image(img))
		return null


func clear_cards():
	for child in get_children():
		if child is Control:
			remove_child(child)
			child.queue_free()


func _input(event):
	if event.is_action_pressed("right"):
		move_focus(1)
	elif event.is_action_pressed("left"):
		move_focus(-1)
	elif event.is_action_pressed("up"):
		navigate_up()
	elif event.is_action_pressed("down"):
		navigate_down()
	elif event.is_action_pressed("shift"):
		TestFeature = not TestFeature
		update_card_positions()


func move_focus(direction):
	focused_card_index += direction
	focused_card_index = clamp(focused_card_index, 0, song_list.size() - 1)
	update_card_positions()


func update_card_positions():
	var center_x = get_viewport().size.x / 2
	var center_y = get_viewport().size.y / 2
	var base_spacing = card_size.x * 0.8
	var depth_factor = 0.3  # Коэффициент для создания эффекта глубины
	var scaling_factor = 0.25  # Коэффициент для изменения масштаба
	var offset_factor = card_size.y * 0.1  # Отступ по вертикали

	for i in range(song_list.size()):
		var card = get_child(i)
		var distance_from_center = abs(i - focused_card_index)
		var offset_x = (i - focused_card_index) * base_spacing
		var offset_y = distance_from_center * offset_factor

		var target_scale = 1.0 - distance_from_center * scaling_factor
		target_scale = clamp(target_scale, 0.5, 1.0)

		var z_offset = -distance_from_center * depth_factor

		var target_position = Vector2(center_x + offset_x - card_size.x / 2, center_y - offset_y - card_size.y / 2)

		# Удаляем старый Tween, если он есть
		if card.has_meta("tween"):
			card.get_meta("tween").kill()

		# Создаем новый Tween для плавного перехода
		var tween = get_tree().create_tween()
		card.set_meta("tween", tween)

		tween.tween_property(card, "position", target_position, 0.3)
		tween.tween_property(card, "scale", Vector2(target_scale, target_scale), 0.3)

		# Используем z_index для управления глубиной отображения
		card.z_index = int(z_offset * 10)



func navigate_up():
	if path_stack.size() > 0:
		current_path = path_stack.pop_back()
		load_cards_at_path(current_path)


func navigate_down():
	if focused_card_index >= 0 and focused_card_index < song_list.size():
		var selected_folder = song_list[focused_card_index]
		var new_path = current_path + "/" + selected_folder
		
		if FileAccess.file_exists(new_path + "/config.txt"):
			show_settings_panel(selected_folder)
		if DirAccess.open(new_path):
			path_stack.append(current_path)
			current_path = new_path
			load_cards_at_path(current_path)


func show_settings_panel(folder_name: String):
	var settings_panel = preload("res://CatalogSystem/Catalog/Presetting.tscn").instantiate()
	add_child(settings_panel)
	settings_panel.CollectNames(current_path, folder_name)
