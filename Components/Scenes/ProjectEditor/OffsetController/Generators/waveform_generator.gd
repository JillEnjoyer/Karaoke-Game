extends Node
class_name WaveformGenerator


func load_waveform_image(
	file_path: String = "", ffmpegPath: String = "",
	size_x: float = 100.0, size_y: float = 70.0, color: String = "black",
):
	if file_path == "" or ffmpegPath == "":
		Debugger.error("File or ffmpeg path is empty.")
		return null
	
	ffmpegPath = "X:/Projects/Godot/Karaoke/karaoke-game/Extensions/ffmpeg.exe"

	var FFmpegProcessorClass = load("res://Components/Scenes/ProjectEditor/OffsetController/Generators/FFmpegProcessor.cs")
	var ffmpeg_processor = FFmpegProcessorClass.new()
	
	ProjectSettings.globalize_path(ffmpegPath)
	Debugger.debug("FFmpeg path: ", ffmpegPath)

	var image_data = ffmpeg_processor.ProcessWithFFmpeg(file_path, ffmpegPath, size_x, size_y, color)
	
	if image_data == null or image_data.size() < 8:
		Debugger.error("Image data is too small or null.")
		return null
	
	var img: Image = Image.new()
	var error = img.load_png_from_buffer(image_data)
	
	if error == OK:
		var texture : ImageTexture = ImageTexture.new()
		texture.set_image(img)
		Debugger.debug("Waveform image size: " + str(texture.get_size()))
		return texture
	else:
		Debugger.error("Error with loading image!")
		return null
