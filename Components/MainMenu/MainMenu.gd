#MainMenu.gd
extends Control

@export var catalog_button: Button
@export var settings_button: Button
@export var quit_button: Button


func _ready():
	var vbox_container = $VBoxContainer
	if vbox_container:
		catalog_button = vbox_container.get_node("catalog_button")
		settings_button = vbox_container.get_node("settings_button")
		quit_button = vbox_container.get_node("quit_button")
		
		if catalog_button:
			catalog_button.connect("pressed", Callable(self, "_on_catalog_button_pressed"))
		if settings_button:
			settings_button.connect("pressed", Callable(self, "_on_settings_button_pressed"))
		if quit_button:
			quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	else:
		Debugger.error("MainMenu.gd", "_ready()", "VBoxContainer not found!")


func _on_catalog_button_pressed():
	UIManager.cleanup_tree()
	UIManager.show_ui("catalog")

func _on_prepare_da_song_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("song_preparation_scene")

func _on_settings_button_pressed():
	UIManager.cleanup_tree()
	UIManager.show_ui("settings")

func _on_quit_button_pressed():
	get_tree().quit()
