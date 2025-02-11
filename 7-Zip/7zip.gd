extends Control

var logger = Core.debugger
var exe_path = ProjectSettings.globalize_path("res://Extensions/7z.exe")


func _ready() -> void:
	pass


func command(arguments: Array, mode: String):
	if mode == "Create":
		create_zip(arguments)
	elif mode == "Extract":
		extract_zip(arguments)


func create_zip(arguments):
	
	var input_files = arguments[0]
	var output_zip = arguments[1]
	
	var args = ["a", output_zip, input_files]
	var result = OS.execute(exe_path, args, [], true, false)
	if result == 0:
		logger.info("7zip.gd", "create_zip()", "Archive created successfully!")
	else:
		logger.error("7zip.gd", "create_zip()", "Error during archive creation!")


func extract_zip(arguments):

	var zip_file = arguments[0]
	var extract_path = arguments[1]

	var args = ["x", zip_file, "-o" + extract_path, "-y"]  
	var result = OS.execute(exe_path, args, [], true, false)
	
	if result == 0:
		logger.info("7zip.gd", "extract_zip()", "Archive unpacked successfully!")
	else:
		logger.info("7zip.gd", "extract_zip()", "Error during archive unpack!")
