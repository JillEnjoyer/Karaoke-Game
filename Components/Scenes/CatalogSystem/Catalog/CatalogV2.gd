extends Control

#@onready var root = UIManager.default_parent
@onready var card_node = $Cards
@onready var card_background = $CardBackground

var card_size = Vector2(550, 700)
var focused_card_index = 1

var base_path = PreferencesData.get_data("catalog_path")
var current_path = base_path
var path_stack = []

var song_list = []

var return_speed = 5.0

var TestFeature: bool = false

var background := []

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
	background = []
	for i in range(song_list.size()):
		var card = create_card(song_list[i], i)
		card_node.add_child(card)


func create_card(song_name: String, index: int) -> Control:
	var card = UIManager.get_desired_node("Card").instantiate() ## Because of further init

	## TODO: Need to add support for loading png/jpg/jpeg/webp
	var icon_path = current_path.path_join(song_name).path_join("Icon")
	var bg_path = current_path.path_join(song_name).path_join("Background")
	
	card.call_deferred("import_data",
		song_name,
		"",
		TextureLoader.load_texture_or_placeholder(icon_path),
		null
	)
	
	background.append(TextureLoader.load_texture_or_placeholder(bg_path))

	card.custom_minimum_size = card_size
	card.pivot_offset = card_size / 2
	card.position = Vector2((index - focused_card_index) * (card_size.x * 0.75), 0)
	
	return card


func clear_cards():
	for child in card_node.get_children():
		if child is Control:
			card_node.remove_child(child)
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
	elif event.is_action_pressed("pause"):
		return_to_main_menu()


func move_focus(direction) -> void:
	card_background.hide_highlight() ## video implementation
	card_background.hide_texture()
	
	focused_card_index += direction
	if focused_card_index < 0:
		focused_card_index = song_list.size() - 1  # Go to the last element
	elif focused_card_index >= song_list.size():
		focused_card_index = 0  # Go to the first element
	
	card_node.get_child(focused_card_index).visible = true
	
	update_card_positions()
	
	if not background:
		return
	
	card_background.apply_texture(background[focused_card_index])
	card_background.show_highlight(current_path.path_join(song_list[focused_card_index])) ## config_path

	#card_node.get_child(focused_card_index).visible = false


func update_card_positions():
	var center_x = card_node.get_viewport().size.x / 2
	var center_y = card_node.get_viewport().size.y / 2
	var base_spacing = card_size.x * 0.8
	var depth_factor = 0.3 
	var scaling_factor = 0.25
	var offset_factor = card_size.y * 0.1

	for i in range(song_list.size()):
		var card = card_node.get_child(i)
		var distance_from_center = abs(i - focused_card_index)
		var offset_x = (i - focused_card_index) * base_spacing
		var offset_y = distance_from_center * offset_factor

		var target_scale = 1.0 - distance_from_center * scaling_factor
		target_scale = clamp(target_scale, 0.5, 1.0)

		var z_offset = -distance_from_center * depth_factor

		var target_position = Vector2(center_x + offset_x - card_size.x / 2, center_y - offset_y - card_size.y / 2)

		if card.has_meta("tween"):
			card.get_meta("tween").kill()

		var tween = card_node.create_tween()
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
		var new_path = current_path.path_join(selected_folder)
		
		if FileAccess.file_exists(new_path.path_join("config.json")):
			show_settings_panel(selected_folder, "single")
			Debugger.debug("Entered song settings panel")
		elif selected_folder == "[Playlists]":
			show_settings_panel(selected_folder, "playlist")
		elif DirAccess.open(new_path):
			path_stack.append(current_path)
			current_path = new_path
			load_cards_at_path(current_path)


func show_settings_panel(folder_name: String, type: String):
	var settings_panel = UIManager.show_ui("PresetPanel")
	Debugger.debug("Sent current_path/folder_name: " + current_path.path_join(folder_name))
	settings_panel.setup_mode(type)
	settings_panel.collect_names(current_path, folder_name, focused_card_index)


func return_catalog_position(album_path: String, chosen_index: int) -> void:
	current_path = album_path
	focused_card_index = chosen_index
	load_cards_at_path(current_path)
	update_card_positions()


func return_to_main_menu() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("MainMenu")
