extends Node

class_name MetadataGetter

var video = Video.new()

func get_all_metadata(path: String) -> Dictionary:
	return video.get_file_meta(path)

func get_duration(path: String) -> float:
	return video.get_file_meta(path)["duration"]

func get_framerate(path: String) -> float:
	return video.get_file_meta(path)["fps"]
