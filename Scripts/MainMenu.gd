#MainMenu.gd
extends Control

@onready var root = get_node("/root/ViewportBase/SubViewportContainer/SubViewport/")

@export var catalog_button: Button
@export var settings_button: Button
@export var quit_button: Button


func _ready():
	var vbox_container = $VBoxContainer
	if vbox_container:
		print("VBoxContainer найден!")
		catalog_button = vbox_container.get_node("catalog_button")
		settings_button = vbox_container.get_node("settings_button")
		quit_button = vbox_container.get_node("quit_button")
		
		if catalog_button:
			print("catalog_button найден!")
			catalog_button.connect("pressed", Callable(self, "_on_catalog_button_pressed"))
		
		if settings_button:
			print("settings_button найден!")
			settings_button.connect("pressed", Callable(self, "_on_settings_button_pressed"))
		
		if quit_button:
			print("quit_button найден!")
			quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	else:
		print("VBoxContainer не найден!")


func load_scene(scene_path: String):
	var scene = load(scene_path).instantiate()
	if scene:
		for child in root.get_children():
			child.queue_free()
		root.add_child(scene)


func _on_catalog_button_pressed():
	load_scene("res://CatalogSystem/Catalog/Catalog.tscn")


func _on_prepare_da_song_btn_pressed() -> void:
	load_scene("res://SongPreparation/SongPreparationScene.tscn")


func _on_settings_button_pressed():
	load_scene("res://Settings/Settings.tscn")


func _on_quit_button_pressed():
	get_tree().quit()
