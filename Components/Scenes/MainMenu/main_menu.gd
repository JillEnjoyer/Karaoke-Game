#MainMenu.gd
extends Control


func _ready():
	pass


func _on_catalog_btn_pressed() -> void:
	UIManager.cleanup_tree()
	if PreferencesData.get_data("style") == "2d":
		UIManager.show_ui("catalog")
	else:
		UIManager.show_ui("catalog_3d")


func _on_editor_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("editor_scene")


func _on_settings_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("settings")


func _on_exit_btn_pressed() -> void:
	get_tree().quit()
