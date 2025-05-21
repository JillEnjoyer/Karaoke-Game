# track_data.gd
extends Node
class_name TrackData

var uuid: String
var object_name: String
var parts: Array[PartData] = []

func _init(p_name: String):
	uuid = str(get_instance_id())
	name = p_name

func add_part(part: PartData):
	parts.append(part)
	part.add_uuid(uuid)
