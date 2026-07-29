# timeline_drop_zone.gd
extends Control

var timeline: Control

func _can_drop_data(_at_position, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "media_file"

func _drop_data(_at_position, data):
	var type_str := "instrumental" 
	match int(data.track_type):
		2: type_str = "acapella"
		1: type_str = "video"
	
	if timeline:
		timeline.add_channel(data.node_name, data.path, data.duration, type_str)
