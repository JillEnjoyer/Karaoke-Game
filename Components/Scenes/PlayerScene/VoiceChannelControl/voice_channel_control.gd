extends Control

signal value_changed_signal(value, ChName)
var player: AudioStreamPlayer
@onready var Number = $NumberLbl
@onready var ChName = $Ch_NameLbl
@onready var Volume = $VolumeSlider

const ZERO_DB_CENTER := 66.66
const ZERO_DB_ZONE := 3.66

func _ready():
	pass

func _on_volume_slider_value_changed(value: float) -> void:
	if abs(value - ZERO_DB_CENTER) <= ZERO_DB_ZONE:
		value = ZERO_DB_CENTER
		$VolumeSlider.value = value  # обновим визуально, чтобы "зафиксировать" ручку
	emit_signal("value_changed_signal", perceptual_volume(value), ChName.text)


func perceptual_volume(value: float) -> float:
	value = clamp(value, 0.0, 100.0)

	if value <= 15.0:
		# lowest part (0–15): from -80 to -12 dB
		return lerp(-80.0, -12.0, value / 15.0)
	elif value <= 33.33:
		# lower third (15–33.33): from -12 to -3 dB
		return lerp(-12.0, -3.0, (value - 15.0) / (33.33 - 15.0))
	elif value <= 66.66:
		# middle third (33.33–66.66): from -3 to 0 dB
		return lerp(-3.0, 0.0, (value - 33.33) / (66.66 - 33.33))
	else:
		# upper third (66.66–100): from 0 to +9 dB
		return lerp(0.0, 9.0, (value - 66.66) / (100.0 - 66.66))
