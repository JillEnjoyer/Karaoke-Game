extends Node
class_name PNGSaveIntruder

## Experimental system that can save (intrude) game/song settings into NEW or already existing png file(s) using alpha channel as data storage.
## Currently it is only interesting as a proof of concept. It is not solving any real problem.
## Might be useful as simpliest steganography method or as a way to cut the number of save files.

@onready var imageSize = Vector2(64, 64) # could be possibly adjusted to store more data

var baseImage = load("res://BlackSquare.png") # Will be removed later

var target_save_location = "res://Preferences" ## will be changed


func _ready() -> void:
	GenerateGeneralSaveFile()
	ReadGeneralSaveFile()


func GenerateGeneralSaveFile() -> void:
	var data_string = GetSaveString()
	var save_path = target_save_location.path_join("game_settings.png")
	
	var image = Image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)
	Debugger.info("Created image with size: " + str(image.get_width()) + "x" + str(image.get_height()))
	#image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)
	
	if image.get_width() == 0 or image.get_height() == 0:
		Debugger.error("Wrong image size")
		return
	
	var data_binary = data_string.to_utf8_buffer()
	var data_index = 0
	
	for y in range(imageSize.y):
		for x in range(imageSize.x):
			if data_index + 2 < data_binary.size():
				var r = data_binary[data_index]
				var g = data_binary[data_index + 1]
				var b = data_binary[data_index + 2]
				image.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0))
				data_index += 3
			else:
				image.set_pixel(x, y, Color(0, 0, 0))
	
	image.save_png(save_path)


func ReadGeneralSaveFile() -> void:
	var file_path = target_save_location.path_join("game_settings.png")
	var image = Image.new()
	image.load(file_path)
	#image.lock()
	var binary_data = PackedByteArray()
	
	for y in range(imageSize.y):
		for x in range(imageSize.x):
			var color = image.get_pixel(x, y)
			binary_data.append(int(color.r * 255))
			binary_data.append(int(color.g * 255))
			binary_data.append(int(color.b * 255))
	
	#image.unlock()
	
	var data_string = binary_data.get_string_from_utf8()
	Debugger.debug("Restored Data: " + str(data_string))


func GenerateSongSaveFile(ParametrList: Dictionary) -> void:
	var data_string = getSaveStringFromDict(ParametrList)
	var save_path = target_save_location.path_join("song_settings.png")

	var image = Image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)

	var data_binary = data_string.to_utf8_buffer()
	var data_index = 0
	
	for y in range(imageSize.y):
		for x in range(imageSize.x):
			if data_index + 2 < data_binary.size():
				var r = data_binary.get_u8(data_index)
				var g = data_binary.get_u8(data_index + 1)
				var b = data_binary.get_u8(data_index + 2)
				image.set_pixel(x, y, Color(r/255.0, g/255.0, b/255.0))
				data_index += 3
			else:
				image.set_pixel(x, y, Color(0, 0, 0))
	
	image.save_png(save_path)


func ReadSongSaveFile() -> void:
	var file_path = target_save_location.path_join("song_settings.png")
	var image = Image.new()
	image.load(file_path)
	image.lock()
	
	var binary_data = PackedByteArray()
	
	for y in range(imageSize.y):
		for x in range(imageSize.x):
			var color = image.get_pixel(x, y)
			binary_data.append(int(color.r * 255))
			binary_data.append(int(color.g * 255))
			binary_data.append(int(color.b * 255))
	
	image.unlock()
	
	var data_string = binary_data.get_string_from_utf8()
	Debugger.debug("Restored Song Data: " + data_string)


func GetSaveString() -> String:
	var data_string = ""
	#data_string += "ResolutionX:" + str(PreferencesData.get_data("ResolutionX")) + "\n"
	data_string += "Language:" + str(PreferencesData.get_data("Language")) + "\n"
	data_string += "WindowMode:" + str(PreferencesData.get_data("WindowMode")) + "\n"
	data_string += "OverallVolume:" + str(PreferencesData.get_data("OverallVolume")) + "\n"
	data_string += "MicStatus:" + str(PreferencesData.get_data("MicStatus")) + "\n"
	data_string += "FramerateLock:" + str(PreferencesData.get_data("FramerateLock")) + "\n"
	#data_string += "PNGSave:" + str(PreferencesData.get_data("PNGSave")) + "\n"
	
	return data_string


func getSaveStringFromDict(ParametrList: Dictionary) -> String:
	var data_string = ""
	for key in ParametrList.keys():
		data_string += key + ":" + str(ParametrList[key]) + "\n"
	
	return data_string
