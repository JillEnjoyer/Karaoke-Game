extends Node

class_name WaveformGenerator

func load_waveform_image(
	file_path: String = "", ffmpegPath: String = "", 
	size_x: int = 100, size_y: int = 70, color: String = "black",
):
	var FFmpegProcessorClass = load("res://Components/SongPreparation/Components/OffsetController/Generators/FFmpegProcessor.cs")
	var ffmpeg_processor = FFmpegProcessorClass.new()
	
	if ffmpegPath == "": 
		ffmpegPath = "W:/Projects/Godot/Karaoke/karaoke-game/Extensions/ffmpeg.exe"
	var image_data = ffmpeg_processor.ProcessWithFFmpeg(file_path, ffmpegPath, size_x, size_y, color)
	
	if image_data == null or image_data.size() < 8:
		Debugger.error("Image data is too small or null.")
		return null
	
	var img : Image = Image.new()
	var error = img.load_png_from_buffer(image_data)
	
	if error == OK:
		var texture : ImageTexture = ImageTexture.new()
		texture.set_image(img)
		return texture
	else:
		Debugger.error("Error with loading image!")
		return null
