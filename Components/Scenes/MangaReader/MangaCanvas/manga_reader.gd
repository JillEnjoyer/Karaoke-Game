## Main script manga_reader.gd
extends Control

@onready var manga_tcp_client = $MangaTCPClient
@onready var manga_page_canvas = $MangaPageCanvas
@onready var manga_remote = $MangaRemote
@onready var animation_player = $AnimationPlayer


func _ready():
	connect_signals()


func connect_signals():
	## tcp
	manga_tcp_client.page_downloaded.connect(manga_page_canvas.build_manga_page)
	manga_tcp_client.file_loaded.connect(manga_remote.update_total_pages)
	manga_tcp_client.clear_page_buffer.connect(manga_page_canvas.clear_buffer)
	## remote
	manga_remote.manga_file_selected.connect(manga_tcp_client.load_manga_file)
	manga_remote.manga_file_selected.connect(manga_page_canvas.clear_buffer)
	manga_remote.manga_page_requested.connect(manga_tcp_client.get_manga_page)

	manga_remote.next_page_requested.connect(manga_page_canvas.next_step)
	manga_remote.prev_page_requested.connect(manga_page_canvas.transition_to_previous_page)
	manga_remote.toggle_remote_requested.connect(_on_toggle_remote)

	## canvas
	manga_page_canvas.page_changed.connect(manga_remote.update_current_page_num)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		leave_scene()

	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		manga_page_canvas.next_step()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		pass


func _on_toggle_remote(is_hidden: bool):
	if is_hidden:
		animation_player.play("hide_control_block")
	else:
		animation_player.play_backwards("hide_control_block")


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
	UIManager.show_ui("MainMenu")


func _exit_tree():
	VocatoolWatchdog.terminate_tool("manga_reader")
