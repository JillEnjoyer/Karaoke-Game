extends Control

var player_scene_fullscreen = false

@onready var PlayerScene = $PlayerScene
#@onready var SearchSystem = $SearchSystem
@onready var animation_player = $AnimationPlayer
@onready var file_dialog = FileDialog.new()
@onready var context_menu = PopupMenu.new()
@onready var control_container = Control.new()

const PLAYER_SCENE_WINDOW_RATIO = 1.5

func _ready() -> void:
	file_dialog_init()
	PlayerScene.size = PlayerScene.size# * PLAYER_SCENE_WINDOW_RATIO
	PlayerScene.debugging = true
	PlayerScene.get_node("VideoRenderer/TextureRect").texture = preload("res://icon.svg")


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

	add_child(dialog)
	dialog.popup_centered()


func _on_yes_pressed():
	UIManager.cleanup_tree()
	UIManager.show_ui("main_menu")


func switch_player_scene_mode():
	if not player_scene_fullscreen:
		animation_player.play("Expand")
		
		print("animation played forward")
		print("size :", PlayerScene.size)
	elif player_scene_fullscreen:
		animation_player.play_backwards("Expand")
		print("animation played back")
		print("size :", PlayerScene.size)
	player_scene_fullscreen = not player_scene_fullscreen


func file_dialog_init():
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	#file_dialog.add_filter("*.png ; PNG Images")
	#file_dialog.add_filter("*.jpg ; JPG Images")
	file_dialog.title = "Choose the project files"
	file_dialog.visible = true
	

	file_dialog.files_selected.connect(_on_files_selected)

	control_container.mouse_filter = Control.MOUSE_FILTER_STOP
	control_container.gui_input.connect(_on_right_click)


func open_dialog():
	file_dialog.popup_centered_ratio(0.8)


func _on_files_selected(paths: PackedStringArray):
	Debugger.debug("song_preparation_scene.gd", "_on_files_selected()", "Choosen files: " + str(paths))
	
	for file in paths:
		#add item to whole choosen list
		pass


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


func handle_selected_files(files: PackedStringArray):
	for file in files:
		Debugger.debug("song_preparation_scene.gd", "handle_selected_files()", "Handling the file: " + str(file))
