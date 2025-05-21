extends Control

func _ready() -> void:
	UIManager.show_ui("main_menu")
	await get_tree().create_timer(1).timeout
	UIManager.show_ui("web_socket", "core")
