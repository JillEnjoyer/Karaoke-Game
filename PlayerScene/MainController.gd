extends Control

@onready var video_manager = preload("res://PlayerScene/Scripts/VideoManager.gd").new()
@onready var audio_manager = preload("res://PlayerScene/Scripts/AudioManager.gd").new()
@onready var subtitle_manager = preload("res://PlayerScene/Scripts/SubtitleManager.gd").new()
@onready var ui_manager = preload("res://PlayerScene/Scripts/UIManager.gd").new()

func _ready() -> void:
	print("MainController ready")
	video_manager.init(self)
	audio_manager.init(self)
	subtitle_manager.init(self)
	ui_manager.init(self)

	# Подключение сигналов и начальная инициализация
	ui_manager.connect_slider(Callable(self, "on_slider_value_changed"))

func on_slider_value_changed(value: float) -> void:
	print("Slider value changed:", value)
	video_manager.seek_video(value)
