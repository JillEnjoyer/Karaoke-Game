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
			print("Error during buffer interaction:", file)
	else:
		print("File is not found:", file_path)
	return null
