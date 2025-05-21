extends Node

signal last_audio_ended

var audio_init = audio_player_instance.new()

# awaited sth like positions["instrumental"/"acapella"][filename] => link

#var positions = {}
var players = {}
var offset_start = {}
var offset_end = {}
var gain = {}
#var pitch = {}
var speed = {}


func init(data_list: Dictionary, type: String):
	var file_paths = {}
	print("/////\n" + str(data_list))
	for version in data_list:
		for file in data_list[version]:
			file_paths[file] = data_list[version][file]["path"]
			
			load_files(file_paths, type)
			load_parameters(file, type, data_list[version][file]["params"])


func load_files(file_paths: Dictionary, file_type: String):
	for file_name in file_paths:
		var player = AudioStreamPlayer.new()
		player.name = file_name
		player.stream = audio_init.get_audio_player(file_paths[file_name])
		UIManager.new_child(player, self)
		
		#if not players.has(file_type):
			#players[file_type] = {}
		players[file_type][file_name] = player
		
		if file_type == "Acapella":
			create_voice_channel_control(player, file_name)


func create_voice_channel_control(Imported_player: AudioStreamPlayer, player_name: String) -> void:
	var instance = UIManager.show_ui("voice_channel_control", "PlayerScene/PlayerSceneUI/Panel/Voice_Channel_HBox")
	instance.get_node("Ch_NameLbl").text = player_name
	instance.connect("value_changed_signal", Callable(self, "on_value_changed"))
func on_value_changed(value, name) -> void:
	Debugger.debug("audio_decoder.gd", "create_voice_channel_control()", "value changed for " + name + ": " + str(value))
	players["Acapella"][name].volume_db = value


func pause_state_command(paused: bool):
	#set_pause_state([instrumental_player, acapella_players], true)
	pass


func set_pause_state(audio_lists: Array, paused: bool):
	for audio_list in audio_lists:
		for key in audio_list:
			if audio_list[key] is AudioStreamPlayer:
				audio_list[key].stream_paused = paused


func make_empty_dict() -> Dictionary:
	var result := {}
	for name in ["Acapella", "Instrumental"]:
		result[name] = {}
	return result

func reset_variables() -> void:
	players = make_empty_dict()
	offset_start = make_empty_dict()
	offset_end = make_empty_dict()
	gain = make_empty_dict()
	speed = make_empty_dict()


func load_parameters(player_name: String, type: String,  parameters: Dictionary):
	offset_start[type][player_name] = parameters["offset_start"]
	offset_end[type][player_name] = parameters["offset_end"]
	gain[type][player_name] = parameters["gain"]
	speed[type][player_name] = parameters["speed"]

# create subfolders for acapella and instrumental on scene
func setup_parameters(type: String, imported_player: AudioStreamPlayer) -> void:
	imported_player.seek(offset_start[type][imported_player.name])
	imported_player.gain = gain[type][imported_player.name]
	imported_player.speed = speed[type][imported_player.name]


func get_all_players() -> Array:
	var result: Array = []
	for player in players["Instrumental"].values():
		result.append(player)
	for player in players["Acapella"].values():
		result.append(player)
	return result


func pause() -> void:
	for player in get_all_players():
		player.stream_paused = true
func resume() -> void:
	for player in get_all_players():
		player.stream_paused = false
		if player.playing != true:
			player.playing = true
