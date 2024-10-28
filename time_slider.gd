extends Control

@onready var slider = $HSlider

signal h_slider_value_changed_signal(value)

func _ready():
	pass


func on_h_slider_value_changed(value: float) -> void:
	# emit signal to PlayerScene
	print(value)
	emit_signal("h_slider_value_changed_signal", value)
