extends Node
class_name AudioPlayerInstance


static func get_audio_player(file_path: String) -> AudioStreamPlayer:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		
		Debugger.error("File is not found: %s" % file_path)
		return null

	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())

	var player := AudioStreamPlayer.new()
	player.stream = stream

	return player
