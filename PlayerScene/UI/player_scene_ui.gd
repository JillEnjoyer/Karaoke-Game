extends Control

@onready var slider = $SliderPanel/HSlider
@onready var button = $VisibilityPanel/Button

signal h_slider_value_changed_signal(value)

var state = false

func _ready():
	slider.connect("value_changed", Callable(self, "on_h_slider_value_changed"))

func on_h_slider_value_changed(value: float) -> void:
	emit_signal("h_slider_value_changed_signal", value)


func _on_button_pressed() -> void:
	if state:
		$AnimationPlayer.play("UP")
	elif not state:
		$AnimationPlayer.play_backwards("UP")
	state = not state
