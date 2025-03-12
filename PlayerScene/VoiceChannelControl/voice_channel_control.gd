extends Control

@onready var Number = $NumberLbl
@onready var ChName = $Ch_NameLbl
@onready var Volume = $VolumeSlider

signal value_changed_signal(value, ChName)

func _ready():
	pass

func _on_volume_slider_value_changed(value: float) -> void:
	emit_signal("value_changed_signal", value, ChName.text)
