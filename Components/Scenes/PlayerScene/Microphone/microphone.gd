extends Node

@onready var mic = $AudioStreamMic

var analyzer = load("res://Components/PlayerScene/Microphone/MicAnalyzer.cs").new()

const threshold: float = 0.1

var mic_buffer: Array = []


func _ready() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MicBus"), 0)
	mic.bus = "MicBus"


func is_similiar(current_player: AudioStreamPlayer) -> bool:
	return analyzer.CompareSamples(get_microphone_buffer(), get_acapella_buffer(current_player), threshold)


func get_microphone_buffer() -> Array:
	var capture = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("MicBus"), 0)
	return capture.get_buffer(1024)
func get_acapella_buffer(current_player: AudioStreamPlayer) -> Array:
	var capture = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("AcapellaBus"), 0)
	return capture.get_buffer(1024)
