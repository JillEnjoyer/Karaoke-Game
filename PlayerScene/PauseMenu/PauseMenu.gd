extends Control

signal Continue

@onready var continue_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/ContinueBtn")
@onready var restart_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/RestartBtn")
@onready var settings_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/SettingsBtn")
@onready var menu_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/MenuBtn")
@onready var desktop_btn = UIManager.default_parent.get_node("PauseMenu/VBoxContainer/DesktopBtn")


func _ready() -> void:
	pass

func _on_continue_btn_pressed() -> void:
	get_tree().paused = false
	self.queue_free()
	
	UIManager.default_parent.get_node("PlayerScene").start_timer_before_play()
	
	emit_signal("Continue")

func _on_restart_btn_pressed() -> void:
	Debugger.info("PauseMenu.gd", "restart()", "Game Restarting...")

func _on_settings_btn_pressed() -> void:
	Debugger.info("PauseMenu", "settings()", "Opening Settings...")

func _on_menu_btn_pressed() -> void:
	Debugger.info("PauseMenu", "menu", "Returning to Main Menu...")

func _on_desktop_btn_pressed() -> void:
	get_tree().quit()
