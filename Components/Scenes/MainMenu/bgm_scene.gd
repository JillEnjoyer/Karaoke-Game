extends Control
@onready var VoicePlayer = $VoiceStreamPlayer
@onready var MusicPlayer = $InstrumentalStreamPlayer
@onready var BGMBox = $BGMBox
@onready var VoiceBox = $VoiceBox

var BGMState = true
var VoiceState = true

var SoundState = {
	true: 0,
	false: -80
} ## in DB


func _ready() -> void:
	MusicPlayer.volume_db = SoundState[BGMState]
	VoicePlayer.volume_db = SoundState[VoiceState]

	BGMBox.button_pressed = BGMState
	VoiceBox.button_pressed = VoiceState


func _on_bgm_button_pressed() -> void:
	BGMState = !BGMState
	BGMBox.button_pressed = BGMState
	Debugger.debug("Current BGM State = " + str(BGMState))

	MusicPlayer.volume_db = SoundState[BGMState]


func _on_voice_button_pressed() -> void:
	VoiceState = !VoiceState
	VoiceBox.button_pressed = VoiceState
	Debugger.debug("Current Voice State = " + str(VoiceState))

	VoicePlayer.volume_db = SoundState[VoiceState]
