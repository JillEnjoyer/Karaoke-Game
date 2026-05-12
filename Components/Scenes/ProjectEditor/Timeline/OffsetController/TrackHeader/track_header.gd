extends PanelContainer

@onready var label_name = $HBox/VBox/LabelName
@onready var label_type = $HBox/VBox/LabelType
@onready var icon_rect = $HBox/Icon

var track_type: String = ""

func setup(node_name: String, type: String):
	track_type = type
	label_name.text = node_name
	label_type.text = type.to_upper()
	
	match type:
		"video":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/video.svg")
		"acapella":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/microphone.svg")
		"instrumental":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/music.svg")


func _get_drag_data(_at_position):
	var preview = Label.new()
	preview.text = "Transfer track: " + label_name.text
	set_drag_preview(preview)
	return {"type": "reorder_track", "old_index": get_index()}
