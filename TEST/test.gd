extends Control

func _ready() -> void:
	var audio = $AudioStreamPlayer
	var file_path = "W:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/Respectless/Audio/[Instrumental]Respectless.mp3"
	var file: FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.READ)
	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	if file != null: 
		stream.data = file.get_buffer(file.get_length())
		if stream:
			audio.stream = stream
			audio.play()
