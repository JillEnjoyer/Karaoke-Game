extends Node

var parent = null


func _ready() -> void:
	UIManager.update_default_parent()
	UIManager.show_ui("main_menu")
