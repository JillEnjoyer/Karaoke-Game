extends Control

@onready var Music = preload("res://MainMenu/Audio/Hide Away [Instrumental].mp3")
@onready var Voice = preload("res://MainMenu/Audio/Hide Away [Acapella].mp3")

@onready var VoicePlayer = $VoiceStreamPlayer
@onready var MusicPlayer = $InstrumentalStreamPlayer
@onready var BGMBox = $BGMBox
@onready var VoiceBox = $VoiceBox

var BGMState = true
var VoiceState = true

var SoundState = {
	true: 0,      # Громкость для включенного состояния
	false: -80    # Громкость для выключенного состояния
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Voice and Music:
		MusicPlayer.stream = Music
		VoicePlayer.stream = Voice
		MusicPlayer.play()
		VoicePlayer.play()
	
	# Устанавливаем начальные значения громкости
	MusicPlayer.volume_db = SoundState[BGMState]
	VoicePlayer.volume_db = SoundState[VoiceState]
	
	# Устанавливаем начальные состояния кнопок
	BGMBox.button_pressed = BGMState
	VoiceBox.button_pressed = VoiceState

func _on_bgm_button_pressed() -> void:
	BGMState = !BGMState
	BGMBox.button_pressed = BGMState
	print("Current BGM State = " + str(BGMState))
	
	# Изменяем громкость в зависимости от состояния BGMState
	MusicPlayer.volume_db = SoundState[BGMState]

func _on_voice_button_pressed() -> void:
	VoiceState = !VoiceState
	VoiceBox.button_pressed = VoiceState
	print("Current Voice State = " + str(VoiceState))
	
	# Изменяем громкость в зависимости от состояния VoiceState
	VoicePlayer.volume_db = SoundState[VoiceState]
