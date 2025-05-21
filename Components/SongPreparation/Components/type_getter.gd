extends Node

class_name TypeGetter

const EXTENSION_TYPES: Dictionary = {
	"video": ["mp4", "mkv", "ogv" ,"avi", "webm", "mov"],
	"audio": ["mp3", "wav", "ogg", "flac", "aac", "m4a"],
	"image": ["png", "jpg", "jpeg", "gif", "bmp"]
}

func get_file_type(path: String) -> String:
	var extension = path.get_extension().to_lower()
	for type in EXTENSION_TYPES.keys():
		if extension in EXTENSION_TYPES[type]:
			return type
	return "unknown"
