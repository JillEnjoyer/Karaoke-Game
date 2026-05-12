extends Control


func _on_manga_reader_btn_pressed() -> void:
	self.queue_free()
	UIManager.show_ui("MangaReader")


func _on_karaoke_btn_pressed() -> void:
	self.queue_free()
	UIManager.show_ui("MainMenu")


func _on_voca_tool_btn_pressed() -> void:
	#UIManager.show_ui("temp_debug_menu")
	Debugger.warning("Not implemented yet...")


func _on_password_generator_btn_pressed() -> void:
	UIManager.show_ui("PasswordGenerator")


func _on_exit_btn_pressed() -> void:
	get_tree().quit()
