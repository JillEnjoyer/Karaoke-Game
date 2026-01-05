# text_voice_comparer.gd
extends Control

@onready var input_text = $TextEdit
@onready var output_text = $CodeEdit
@onready var path_text = $HBoxContainer/RichTextLabel

## test paths (could be changed later)
var vosk_handler_path = ProjectSettings.globalize_path(PreferencesData.get_ext_path("vosk_handler"))
var ffmpeg_path = ProjectSettings.globalize_path(PreferencesData.get_ext_path("ffmpeg"))
var vosk_model_path = ProjectSettings.globalize_path("res://Extensions/Models/[ENG]vosk-model-0.22-lgraph")

func _on_button_pressed() -> void:
	var file_picker = FilePicker.new()
	files_selected(file_picker.open_file_picker())


func files_selected(paths: PackedStringArray):
	Debugger.debug("Choosen files: " + str(paths))
	if paths.size() > 0:
		var file_path := paths[0]
		path_text.text = file_path
		return
	var error = "No files chosen"
	Debugger.warning(error)
	path_text.text = error


func _on_start_btn_pressed() -> void:
	if path_text.text != "":
		var thread = Thread.new()
		thread.start(process_audio_file.bind(path_text.text))


func process_audio_file(file_path: String) -> void:
	var output := []
	var global_handler_path = ProjectSettings.globalize_path(vosk_handler_path)
	var global_ffmpeg_path = ProjectSettings.globalize_path(ffmpeg_path)
	var global_audio_path = ProjectSettings.globalize_path(file_path)

	var args = [global_audio_path, vosk_model_path, global_ffmpeg_path]
	
	var result = OS.execute(global_handler_path, args, output, true, false)
	
	# return to main thread to update UI
	call_deferred("_on_process_finished", result, output)


func _on_process_finished(result, output):
	if result == 0:
		output_text.text = str(output[0])
		Debugger.info("Ready!")
		#var res: Array = TextComparisor.align_text_with_vosk(input_text.text, output_text.text)
		#output_text.text = str(res)
	else:
		Debugger.error("Error code: " + str(result))
