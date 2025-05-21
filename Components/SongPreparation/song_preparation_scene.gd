extends Control

var player_scene_fullscreen = false
var cp_appeared = false

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

var chosen_files := []

func _ready() -> void:
	#file_dialog_init()
	#player_scene.size = player_scene.size
	player_scene.debugging = true
	player_scene.get_node("VideoRenderer/TextureRect").texture = preload("res://icon.svg")
	player_scene.hide_slider()

func _input(event):
	if Input.is_action_just_pressed("pause"):
		leave_scene()
	elif Input.is_action_just_pressed("expand"):
		Debugger.debug("song_preparation_scene.gd", "_input()", "Screen expanded")
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
		player_scene.hide_slider()
	else:
		animation_player.play("Expand")
		player_scene.show_slider()
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
		0: Debugger.info("song_preparation_scene.gd", "_on_menu_selected()", "Opening file...")
		1: Debugger.info("song_preparation_scene.gd", "_on_menu_selected()", "Path is copied!")
		2: Debugger.info("song_preparation_scene.gd", "_on_menu_selected()", "Deleting the file...")


func _on_new_project_btn_pressed() -> void:
	Debugger.debug("song_preparation_scene.gd", "_on_new_project_btn_pressed", "Create new song project...")
	var new_project: Control = UIManager.show_ui("new_project", self)
	new_project.connect("new_project_closed", Callable(self, "new_project_created"))
func new_project_created(result: bool):
	if result:
		functionality_init()


func _on_open_existing_btn_pressed() -> void:
	Debugger.debug("song_preparation_scene.gd", "_on_open_existing_btn_pressed", "Open existing song project...")
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
	Debugger.debug("song_preparation_scene.gd", "_on_masking_layer_btn_pressed", "Masking layer is now active")
func _on_subtitle_layer_btn_pressed() -> void:
	Debugger.debug("song_preparation_scene.gd", "_on_subtitle_layer_btn_pressed", "Subtitle layer is now active")
func _on_fm_btn_pressed() -> void:
	Debugger.debug("song_preparation_scene.gd", "_on_fm_btn_pressed", "FM is opened")
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


func save_project() -> void:
	"""1. Save choosen project files as copies to catalog folder (owerwrite if asked)"""
	
	"""2. Save their parameters: Names, Offsets and etc in standartized json type"""
