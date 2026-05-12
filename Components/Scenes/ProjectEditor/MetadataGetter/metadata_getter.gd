extends Node
class_name MetadataGetter


static func get_all_metadata(path: String) -> Dictionary:
	return Video.get_file_meta(path)


static func get_duration(path: String) -> float:
	return Video.get_file_meta(path)["duration"]


static func get_framerate(path: String) -> float:
	return Video.get_file_meta(path)["fps"]
