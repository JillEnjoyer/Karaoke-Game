extends Control

@onready var root = get_node("/root/ViewportBase/SubViewportContainer/SubViewport")
@onready var catalog_base = root.get_node("Catalog")

var audio_player_init = audio_player_instance.new()
var text_loader = texture_loader.new()

var card_size = Vector2(550, 700)
var focused_card_index = 1

var base_path = Core.get_node("PreferencesData").getData("catalog_path")
var current_path = base_path
var path_stack = []

var song_list = []

var return_speed = 5.0

var TestFeature: bool = false

func _ready():
	load_cards_at_path(current_path)


func load_cards_at_path(path: String):
	clear_cards()
	song_list.clear()
	var dir_access = DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full_path = path + "/" + file_name
				if DirAccess.open(full_path):
					song_list.append(file_name)
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
	
	create_cards()
	move_focus(-1)


func create_cards():
	for i in range(song_list.size()):
		var card = create_card(song_list[i], i)
		catalog_base.add_child(card)


func create_card(song_name: String, index: int) -> Control:
	var card = preload("res://CatalogSystem/Card/Card.tscn").instantiate()
	card.song_title = song_name

	var icon_path = current_path + "/" + song_name + "/Icon.png"
	var bg_path = current_path + "/" + song_name + "/Background.png"
	
	#print("Загружаемый путь:", icon_path)
	
	card.album_art = text_loader.load_texture_or_placeholder(icon_path)
	card.background = text_loader.load_texture_or_placeholder(bg_path)

	card.custom_minimum_size = card_size
	card.pivot_offset = card_size / 2
	card.position = Vector2((index - focused_card_index) * (card_size.x * 0.75), 0)
	
	return card


func clear_cards():
	for child in catalog_base.get_children():
		if child is Control:
			catalog_base.remove_child(child)
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
	if focused_card_index < 0:
		focused_card_index = song_list.size() - 1  # Go to the last element
	elif focused_card_index >= song_list.size():
		focused_card_index = 0  # Go to the first element
	update_card_positions()


func update_card_positions():
	var center_x = catalog_base.get_viewport().size.x / 2
	var center_y = catalog_base.get_viewport().size.y / 2
	var base_spacing = card_size.x * 0.8
	var depth_factor = 0.3 
	var scaling_factor = 0.25
	var offset_factor = card_size.y * 0.1

	for i in range(song_list.size()):
		var card = catalog_base.get_child(i)
		var distance_from_center = abs(i - focused_card_index)
		var offset_x = (i - focused_card_index) * base_spacing
		var offset_y = distance_from_center * offset_factor

		var target_scale = 1.0 - distance_from_center * scaling_factor
		target_scale = clamp(target_scale, 0.5, 1.0)

		var z_offset = -distance_from_center * depth_factor

		var target_position = Vector2(center_x + offset_x - card_size.x / 2, center_y - offset_y - card_size.y / 2)

		if card.has_meta("tween"):
			card.get_meta("tween").kill()

		var tween = catalog_base.create_tween()
		card.set_meta("tween", tween)

		tween.tween_property(card, "position", target_position, 0.3)
		tween.tween_property(card, "scale", Vector2(target_scale, target_scale), 0.3)

		card.z_index = int(z_offset * 10)


func navigate_up():
	if path_stack.size() > 0:
		current_path = path_stack.pop_back()
		load_cards_at_path(current_path)


func navigate_down():
	if focused_card_index >= 0 and focused_card_index < song_list.size():
		var selected_folder = song_list[focused_card_index]
		var new_path = current_path + "/" + selected_folder
		
		if FileAccess.file_exists(new_path + "/config.json"):
			show_settings_panel(selected_folder, "single")
			print("Entered song settings panel")
		elif selected_folder == "[Playlists]":
			show_settings_panel(selected_folder, "playlist")
		elif DirAccess.open(new_path):
			path_stack.append(current_path)
			current_path = new_path
			load_cards_at_path(current_path)


func show_settings_panel(folder_name: String, type: String):
	var settings_panel = UIManager.show_ui("preset_panel")
	print("Sent current_path/folder_name:", current_path, "/", folder_name)
	settings_panel.setup_mode(type)
	settings_panel.CollectNames(current_path, folder_name)
