# editor_scene.gd
extends Control

@onready var type_getter = TypeGetter.new()
@onready var context_menu = PopupMenu.new()
@onready var metadata_getter = MetadataGetter.new()

@onready var new_project_btn = $ControlPanel/NewProjectBtn
@onready var open_existing_btn = $ControlPanel/OpenExistingBtn
@onready var close_project_btn = $ControlPanel/CloseProjectBtn
@onready var player_scene = $PlayerScene
@onready var animation_player = $AnimationPlayer
@onready var timeline = $Timeline

#@onready var color_picker = $ControlPanel/ColorPickerButton

var project_opened = false
var player_scene_fullscreen = false
var cp_appeared = false

var chosen_files := []


func _ready() -> void:
	#file_dialog_init()
	#player_scene.size = player_scene.size
	player_scene.editor_mode = true
	player_scene.get_node("VideoManager/TextureRect").texture = preload("res://icon.svg") ## change with no media icon :(


func _input(event):
	if Input.is_action_just_pressed("pause"):
		leave_scene()
	elif Input.is_action_just_pressed("expand"):
		Debugger.debug("Screen expanded")
		switch_player_scene_mode()


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
	UIManager.show_ui("main_menu")


func switch_player_scene_mode():
	if player_scene_fullscreen:
		animation_player.play_backwards("Expand")
	else:
		animation_player.play("Expand")
	player_scene_fullscreen = not player_scene_fullscreen


#control_container.mouse_filter = Control.MOUSE_FILTER_STOP
#control_container.gui_input.connect(_on_right_click)

func open_fm(type: String) -> void:
	var file_picker = FilePicker.new()
	files_selected(file_picker.open_file_picker())


func files_selected(paths: PackedStringArray):
	Debugger.debug("Choosen files: " + str(paths))
	for path in paths:
		var type = type_getter.get_file_type(path)
		chosen_files.append({
		"path": path,
		"type": type,
		"duration": metadata_getter.get_duration(path)
	})
	functionality_init()


func _on_right_click(event):
	Debugger.debug("song_preparation_scene.gd", "_on_right_click()", "RMC detected")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		context_menu.set_position(event.global_position)
		context_menu.popup()


func _on_menu_selected(id: int):
	match id:
		0: Debugger.info("Opening file...")
		1: Debugger.info("Path is copied!")
		2: Debugger.info("Deleting the file...")


func _on_new_project_btn_pressed() -> void:
	Debugger.debug("Create new song project...")
	var new_project: Control = UIManager.show_ui("new_project", self)
	new_project.connect("new_project_closed", Callable(self, "new_project_created"))
func new_project_created(result: bool):
	if result:
		functionality_init()


func _on_open_existing_btn_pressed() -> void:
	Debugger.debug("Open existing song project...")
	open_fm("open_existing")


func _on_color_picker_btn_pressed() -> void:
	Debugger.debug("Color picker state is changed to " + str(cp_appeared))
	if cp_appeared:
		cp_appeared = false
		animation_player.play("appear_cp")
	else:
		animation_player.play_backwards("appear_cp")
		await animation_player.animation_finished
		cp_appeared = true


func _on_masking_layer_btn_pressed() -> void:
	Debugger.debug("Masking layer is now active")
func _on_subtitle_layer_btn_pressed() -> void:
	Debugger.debug("Subtitle layer is now active")
func _on_fm_btn_pressed() -> void:
	Debugger.debug("FM is opened")
	open_fm("all")


func functionality_init() -> void:
	new_project_btn.visible = false
	open_existing_btn.visible = false
	close_project_btn.visible = true
	add_files_to_timeline()
func functionality_deinit() -> void:
	new_project_btn.visible = true
	open_existing_btn.visible = true
	close_project_btn.visible = false


func add_files_to_timeline() -> void:
	timeline.import_choosen_files(chosen_files)


func _on_close_project_btn_pressed() -> void:
	save_project()
	functionality_deinit()


func save_project() -> Dictionary:
	var project_data = {
		"files": {
			"acapella": {},
			"instrumental": {},
			"video": {
				"jumpers": [] # Видео джамперы в общем списке
			}
		},
		"characters": []
	}

	# Получаем список всех врапперов с таймлайна
	# Предполагаем, что timeline имеет метод get_wrappers() или просто get_children()
	var wrappers = timeline.get_children() 

	for wrapper in wrappers:
		# Пропускаем, если это не враппер (например, какие-то UI элементы)
		if not wrapper.has_method("prepare_export_timecodes"): 
			continue
			
		var type = wrapper.node_type # "acapella", "instrumental", "video"
		var char_name = wrapper.node_name # "Alastor", "Original" и т.д.
		var path = wrapper.initial_path
		
		# Генерируем список джамперов для конкретного файла
		var jumpers = []
		
		# СОРТИРОВКА ВАЖНА: Сначала сортируем сегменты по положению X
		wrapper.sort_segments()
		
		for seg in wrapper.segments:
			# Логика перевода Cutoff в TimeCode
			# start_from (внутри файла) = сколько мы отрезали слева
			var internal_start = seg.left_cutoff
			# end_at (внутри файла) = длительность минус сколько отрезали справа
			var internal_end = seg.total_duration - seg.right_cutoff
			
			# Формируем структуру джампера
			var jumper = {}
			
			# Если это самый первый сегмент и он начинается с 0, можно использовать start_from
			# Но для унификации лучше использовать from/to
			jumper["from_time"] = internal_start
			jumper["to_time"] = internal_end
			
			# Если есть повторы (нужно реализовать логику в сегменте, пока ставим 1)
			# if seg.repeats > 1: jumper["repeats"] = seg.repeats
			
			jumpers.append(jumper)
		
		# Добавляем null в конец, как маркер остановки
		jumpers.append({"stop_at": null})
		
		# Запихиваем в итоговый словарь в зависимости от типа
		match type:
			"acapella":
				if not project_data["files"]["acapella"].has(char_name):
					project_data["files"]["acapella"][char_name] = {}
				
				project_data["files"]["acapella"][char_name] = {
					"path": path,
					"jumpers": jumpers
				}
				# Добавляем в список персонажей, если еще нет
				if not char_name in project_data["characters"]:
					project_data["characters"].append(char_name)
					
			"instrumental":
				if not project_data["files"]["instrumental"].has(char_name):
					project_data["files"]["instrumental"][char_name] = {}
					
				project_data["files"]["instrumental"][char_name] = {
					"path": path,
					"jumpers": jumpers
				}
				
			"video":
				# Видео имеет чуть другую структуру в твоем примере
				if not project_data["files"]["video"].has(char_name):
					project_data["files"]["video"][char_name] = {"path": path}
				
				# Добавляем ID к каждому джамперу и кидаем в общий массив jumpers видео
				for j in jumpers:
					var video_j = j.duplicate()
					video_j["id"] = char_name # ID видео источника
					project_data["files"]["video"]["jumpers"].append(video_j)

	Debugger.info("Project saved structure generated.")
	Debugger.debug(JSON.stringify(project_data, "\t"))
	return project_data


func temp_expose_VOSK_result(data: String) -> void:
	$TextEdit.text = JSON.stringify(data)


func _on_vosk_btn_pressed() -> void:
	pass # Replace with function body.
