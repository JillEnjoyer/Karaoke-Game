extends Node
#class_name FFMPEGExecutor

# Function to run FFMPEG with specified arguments
func run_ffmpeg_command(input_file: String, output_file: String):
	var ffmpeg_path = "ffmpeg" # Make sure FFMPEG is available in the system path
	var args = [
		"-i", input_file, # Input file
		"-an", # Remove audiotrack
		"-c:v", "libx264", # Use H.264 codec
		"-crf", "18", # Balance quality and file size - optimal bitrate
		"-preset", "slow", # Quality optimization (can choose fast, slow, slower, etc.)
		"-pix_fmt", "yuv420p", # Set pixel format for compatibility
		output_file # Output file
	]

	var output = []
	var error = []

	var result = OS.execute(ffmpeg_path, args, output, error)
	if result == OK:
		print("FFMPEG executed successfully.")
		print("FFMPEG output: ", output.join("\n"))
	else:
		print("Failed to execute FFMPEG, error code: ", result)
		print("FFMPEG error output: ", error.join("\n"))
