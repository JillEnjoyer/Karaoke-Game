extends Node
class_name FFMPEGExecutor


## Function to run FFMPEG with specified arguments
func run_ffmpeg_command(input_file_path: String, output_file_path: String, args: Array):
	var ffmpeg_path = PreferencesData.get_ext_path("ffmpeg")

	var output = []
	var error = []

	var result = OS.execute(ffmpeg_path, args, output, error)
	if result == OK:
		Debugger.info("FFMPEG executed successfully.\nFFMPEG output: " + output.join("\n"))
	else:
		Debugger.info("Failed to execute FFMPEG, error code: " + str(result) + "\nFFMPEG output: " + "FFMPEG error output: " + error.join("\n"))


func convert_video_file(input_file_path: String, output_file_path: String) -> void:
	var args = [
		"-i", input_file_path,
		"-an", # Remove audiotrack
		"-c:v", "libx264", # Use H.264 codec
		"-crf", "18", # Balance quality and file size - optimal bitrate
		"-preset", "slow", # Quality optimization (can choose fast, slow, slower, etc.)
		"-pix_fmt", "yuv420p", # Set pixel format for compatibility
		output_file_path
	]
	run_ffmpeg_command(input_file_path, output_file_path, args)
