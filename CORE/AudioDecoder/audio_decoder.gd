extends Node

var audio_init = audio_player_instance.new()

var instrumental_link = ""
#var instrumental_list = {}
var acapella_list = {}

var instrumental_position = 0.0
var acapella_positions = {}

var instrumental_player: AudioStreamPlayer = null
#var instrumental_players = {}
var acapella_players = {}



func load_instrumental_file(file_path: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = audio_init.get_audio_player(file_path)
	UIManager.add_child(player)
	return player
func load_acapella_file(file_path: String, character_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = audio_init.get_audio_player(file_path)
	add_child(player)
	acapella_players[character_name] = player
	create_voice_channel_control(character_name)
	return player
func load_audio_files(base_path: String, audio_type: String) -> void:
	
	
	if audio_type == "instrumental":
		var instrumental_file = base_path
		Debugger.info("audio_decoder.gd", "load_audio_files()", "Trying to load instrumental from: " + instrumental_file)
		instrumental_player = load_instrumental_file(instrumental_file)
		Debugger.info("audio_decoder.gd", "load_audio_files()", "Instrumental loaded successfully.")
	elif audio_type == "acapella":
		Debugger.info("audio_decoder.gd", "load_audio_files()", "Acapella list: " + str(acapella_list))
		for acapella_group in acapella_list.keys():
			for character_name in acapella_list[acapella_group]:
				var acapella_file = base_path + character_name + ".mp3"
				Debugger.info("audio_decoder.gd", "load_audio_files()", "Trying to load acapella for character " + character_name + " from: " + acapella_file)
				load_acapella_file(acapella_file, character_name)
				Debugger.info("audio_decoder.gd", "load_audio_files()", "Acapella " + acapella_file + " loaded successfully.")



func create_voice_channel_control(character_name: String) -> void:
	var instance = UIManager.show_ui("voice_channel_control_scene", "PlayerScene/Voice_Channel_HBox")
	print(instance.name)
	instance.get_node("Ch_NameLbl").text = character_name
	instance.connect("value_changed_signal", Callable(self, "on_value_changed"))
func on_value_changed(value, ChName) -> void:
	Debugger.info("audio_decoder.gd", "create_voice_channel_control()", "value changed for " + ChName + ": " + str(value))
	acapella_players[ChName].volume_db = -10 + value/10#-80 to 9

func pause_state_command(paused: bool):
	set_pause_state([instrumental_player, acapella_players], true)


func set_pause_state(audio_lists: Array, paused: bool):
	for audio_list in audio_lists:
		for key in audio_list:
			if audio_list[key] is AudioStreamPlayer:
				audio_list[key].stream_paused = paused
