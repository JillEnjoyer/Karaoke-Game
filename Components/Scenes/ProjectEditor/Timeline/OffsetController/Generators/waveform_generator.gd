extends Node
class_name WaveformGenerator


static func load_waveform_image(
	file_path: String = "",
	ffmpegPath: String = "",
	color: String = "black",
) -> Dictionary:

	ffmpegPath = ProjectSettings.globalize_path(PreferencesData.get_ext_path("ffmpeg"))

	var duration: float = get_file_duration(file_path)
	var size_x: int = int(duration * 5) ## change with duration * Constants.controller_wrapper_px_to_sec_ratio
	var size_y: int = int(70.0) ## change with Constants.controller_wrapper_size_y

	var FFmpegProcessorClass = preload("uid://cm4a3nx6a8iyx")
	var ffmpeg_processor = FFmpegProcessorClass.new()
	
	ProjectSettings.globalize_path(ffmpegPath)
	Debugger.debug("FFmpeg path: ", ffmpegPath)

	var image_data = ffmpeg_processor.ProcessWithFFmpeg(file_path, ffmpegPath, size_x, size_y, color)
	
	if image_data == null or image_data.size() < 8:
		Debugger.error("Image data is too small or null.")
		return {}
	
	var img: Image = Image.new()
	var error = img.load_png_from_buffer(image_data)
	
	if error == OK:
		var texture : ImageTexture = ImageTexture.new()
		texture.set_image(img)
		Debugger.debug("Waveform image size: " + str(texture.get_size()))
		return {
			"texture": texture,
			"size_x": size_x,
			"size_y": size_y,
			"duration": duration
		}
	else:
		Debugger.error("Error with loading image!")
		return {}


## TODO: Create static DataTypeGetter to simplify control of file format
static func get_file_duration(file_path: String = "") -> float:
	var global_path = ProjectSettings.globalize_path(file_path)
	
	if not FileAccess.file_exists(global_path):
		return -1.0
		
	var file = FileAccess.open(global_path, FileAccess.READ)
	var bytes = file.get_buffer(file.get_length())
	
	var stream = AudioStreamMP3.new()
	stream.data = bytes
	
	return stream.get_length()