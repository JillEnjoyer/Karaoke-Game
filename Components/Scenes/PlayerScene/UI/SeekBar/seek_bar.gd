extends Control

## Seek bar will be used only in Training mode to jump through file to find certain time
## But, main way to seek will be a list of lines and pressing line will jump at the beginning of it

@onready var h_slider = $HSlider


func _start() -> void:
	pass


func _on_h_slider_value_changed(value: float) -> void:
	pass # Replace with function body.
