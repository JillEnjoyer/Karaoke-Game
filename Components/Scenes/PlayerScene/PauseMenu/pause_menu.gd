extends Control

signal Continue
signal Restart
signal MainMenu

@onready var continue_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/ContinueBtn")
@onready var restart_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/RestartBtn")
@onready var settings_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/SettingsBtn")
@onready var menu_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/MenuBtn")
@onready var desktop_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/DesktopBtn")

#@onready var player_scene = UIManager.default_parent.get_node("MediaPlayer")


func _ready() -> void:
	pass


func _on_continue_btn_pressed() -> void:
	get_tree().paused = false
	self.queue_free()
	
	emit_signal("Continue")


func _on_restart_btn_pressed() -> void:
	Debugger.info("Game Restarting...")

	emit_signal("Restart")


func _on_settings_btn_pressed() -> void:
	Debugger.info("Opening Settings...")

	UIManager.show_ui("SettingsMenu", "PlayerScene/PauseMenu")


func _on_menu_btn_pressed() -> void:
	Debugger.info("Returning to Main Menu...")

	emit_signal("MainMenu")


func _on_desktop_btn_pressed() -> void:
	get_tree().quit()
