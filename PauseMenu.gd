extends Control

signal Continue

@onready var continue_btn = $ContinueButton
@onready var restart_btn = $RestartButton
@onready var settings_btn = $SettingsButton
@onready var menu_btn = $MenuButton
@onready var desktop_btn = $DesktopButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#continue_btn.connect("pressed", Callable(self, "_on_continue_btn_pressed"))
	#restart_btn.connect("pressed", Callable(self, "_on_restart_btn_pressed"))
	#settings_btn.connect("pressed", Callable(self, "_on_settings_btn_pressed"))
	#menu_btn.connect("pressed", Callable(self, "_on_menu_btn_pressed"))
	#desktop_btn.connect("pressed", Callable(self, "_on_desktop_btn_pressed"))

func _on_continue_btn_pressed() -> void:
	# Убираем сцену паузы и продолжаем игру
	get_tree().paused = false  # Убираем глобальную паузу
	self.queue_free()  # Удаляем меню паузы
	
	# Запускаем таймер перед возобновлением игры
	get_node("/root/PlayerScene").start_timer_before_play()  # Запуск таймера
	
	emit_signal("Continue")  # Можно использовать сигнал для других действий

func _on_restart_btn_pressed() -> void:
	# Логика перезапуска игры
	print("Game Restarting...")

func _on_settings_btn_pressed() -> void:
	# Логика открытия настроек
	print("Opening Settings...")

func _on_menu_btn_pressed() -> void:
	# Логика возврата в главное меню
	print("Returning to Main Menu...")

func _on_desktop_btn_pressed() -> void:
	# Логика выхода на рабочий стол
	print("Exiting to Desktop...")
	get_tree().quit()
