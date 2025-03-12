extends Node

var baseImage = load("res://BlackSquare.png")
@onready var imageSize = Vector2(64, 64)
var targetSaveLoc = "res://Preferences/"

func _ready() -> void:
	GenerateGeneralSaveFile()
	ReadGeneralSaveFile()

func GenerateGeneralSaveFile() -> void:
	var data_string = getSaveString()
	var save_path = targetSaveLoc + "game_settings.png"
	
	var image = Image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)
	print("Created image with size: ", image.get_width(), "x", image.get_height())
	#image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)
	
	if image.get_width() == 0 or image.get_height() == 0:
		print("Ошибка: Неверный размер изображения.")
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
	var file_path = targetSaveLoc + "game_settings.png"
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
	print("Restored Data: ", data_string)

func GenerateSongSaveFile(ParametrList: Dictionary) -> void:
	var data_string = getSaveStringFromDict(ParametrList)
	var save_path = targetSaveLoc + "song_settings.png"
	
	var image = Image.new()
	image.create(int(imageSize.x), int(imageSize.y), false, Image.FORMAT_RGB8)
	
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
	var file_path = targetSaveLoc + "song_settings.png"
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
	print("Restored Song Data: ", data_string)


func getSaveString() -> String:
	var data_string = ""
	data_string += "ResolutionX:" + str(PreferencesData.getData("ResolutionX")) + "\n"
	data_string += "Language:" + str(PreferencesData.getData("Language")) + "\n"
	data_string += "WindowMode:" + str(PreferencesData.getData("WindowMode")) + "\n"
	data_string += "OverallVolume:" + str(PreferencesData.getData("OverallVolume")) + "\n"
	data_string += "MicStatus:" + str(PreferencesData.getData("MicStatus")) + "\n"
	data_string += "FramerateLock:" + str(PreferencesData.getData("FramerateLock")) + "\n"
	#data_string += "PNGSave:" + str(PreferencesData.getData("PNGSave")) + "\n"
	
	return data_string


func getSaveStringFromDict(ParametrList: Dictionary) -> String:
	var data_string = ""
	for key in ParametrList.keys():
		data_string += key + ":" + str(ParametrList[key]) + "\n"
	
	return data_string
