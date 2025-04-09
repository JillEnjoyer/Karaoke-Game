extends Node

signal last_audio_ended

var audio_init = audio_player_instance.new()

# awaited sth like positions["instrumental"/"acapella"][filename] => link

var positions = {}
var players = {}
var offset_start = {}
var offset_end = {}
var gain = {}
var pitch = {}
var speed = {}


func init(data_list: Dictionary, type: String):
	var file_paths = {}
	print("/////\n" + str(data_list))
	for version in data_list:
		for file in data_list[version]:
			file_paths[file] = data_list[version][file]["path"]
			
			load_files(file_paths, type)


func load_files(file_paths: Dictionary, file_type: String):
	reset_variables()
	
	for file_name in file_paths:
		var player = AudioStreamPlayer.new()
		player.name = file_name
		player.stream = audio_init.get_audio_player(file_paths[file_name])
		UIManager.new_child(player)
		
		if not players.has(file_type):
			players[file_type] = {}
		players[file_type][file_name] = player


func create_voice_channel_control(character_name: String) -> void:
	var instance = UIManager.show_ui("voice_channel_control_scene", "PlayerScene/Voice_Channel_HBox")
	print(instance.name)
	instance.get_node("Ch_NameLbl").text = character_name
	instance.connect("value_changed_signal", Callable(self, "on_value_changed"))
func on_value_changed(value, ChName) -> void:
	Debugger.info("audio_decoder.gd", "create_voice_channel_control()", "value changed for " + ChName + ": " + str(value))
	#acapella_players[ChName].volume_db = -10 + value/10#-80 to 9

func pause_state_command(paused: bool):
	#set_pause_state([instrumental_player, acapella_players], true)
	pass


func set_pause_state(audio_lists: Array, paused: bool):
	for audio_list in audio_lists:
		for key in audio_list:
			if audio_list[key] is AudioStreamPlayer:
				audio_list[key].stream_paused = paused


func reset_variables() -> void:
	positions = {}
	players = {}
	offset_start = {}
	offset_end = {}
	gain = {}
	pitch = {}
	speed = {}
