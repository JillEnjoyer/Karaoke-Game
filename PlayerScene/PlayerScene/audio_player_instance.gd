extends Node

class_name audio_player_instance

func get_audio_player(file_path):
	var file: FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	if file != null:
		var stream = AudioStreamMP3.new()
		stream.data = file.get_buffer(file.get_length())
		if stream:
			return stream
		else:
			Debugger.error("", "", "Error during buffer interaction: " + str(file))
	else:
		Debugger.error("", "", "File is not found: " + str(file_path))
	return null
