extends Node

var thread: Thread = Thread.new()

signal transcription_complete(result)

func _ready():
	return thread.start(Callable(self, "handler"))


func handler(audio_path, model_path):
	var args = [
		"res://Extensions/Vosk_Handler_V1.1.exe",
		audio_path,
		model_path,
		path_globalizer("res://Extensions/ffmpeg.exe")
	]
	
	var output = ""
	var error = ""
	var exit_code = OS.execute(args[0], args.slice(1), output, error)
	if exit_code == OK:
		error = "Python script executed successfully"
	else:
		error = "Error while executing Python script"
	
	print(error, "\n\n\n\n")
	print(output)
	
	thread.wait_to_finish()
	
	thread.free()
	thread = null
	
	return output


func path_globalizer(local_path):
	return ProjectSettings.globalize_path(local_path)
