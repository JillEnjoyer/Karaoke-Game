extends Node
class_name VoskHandler

signal transcription_complete(result)

var thread: Thread = Thread.new()

var vosk_handler = PreferencesData.get_ext_path("Vosk_Handler")
var ffmpeg_path = PreferencesData.get_ext_path("ffmpeg")


func transcribe(audio_path: String, model_path: String) -> void:
	if thread and thread.is_alive():
		return
	thread = Thread.new()
	thread.start(Callable(self, "_thread_handler").bind(audio_path, model_path))


func _thread_handler(audio_path: String, model_path: String) -> void:
	var args = [
		path_globalizer(vosk_handler),
		audio_path,
		model_path,
		path_globalizer(ffmpeg_path)
	]
	var output = ""
	var error = ""
	var exit_code = OS.execute(args[0], args, output, error)
	if exit_code != OK:
		Debugger.error("Error while executing Vosk handler: " + error)
		return
	call_deferred("_emit_transcription_complete", output)


func _emit_transcription_complete(transcription_result: String) -> void:
	emit_signal("transcription_complete", transcription_result)
	thread.wait_to_finish()
	thread = null


func path_globalizer(local_path):
	return ProjectSettings.globalize_path(local_path)
