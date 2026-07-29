extends HBoxContainer

var file_path: String
var media_pool: Control

@onready var option_button = $OptionButton
@onready var name_lbl = $NameLbl


func setup(media_pool_in: Control, data: Dictionary):
	media_pool = media_pool_in
	file_path = data.path
	name_lbl.text = data.name
	
	option_button.clear()
	option_button.add_item("Video", 1)
	option_button.add_item("Acapella", 2)
	option_button.add_item("Instrumental", 3)
	option_button.add_item("Drums", 4)
	option_button.add_item("Bass", 5)
	
	var target_index = option_button.get_item_index(data.track_type)
	if target_index != -1:
		option_button.selected = target_index


func _on_option_button_item_selected(index: int):
	var type_id = option_button.get_item_id(index)
	media_pool.update_file_type(file_path, type_id)


func _get_drag_data(_at_position):
	var data = media_pool.chosen_files[file_path]
	
	var preview = Label.new()
	preview.text = data.name
	set_drag_preview(preview)
	
	return {
		"type": "media_file",
		"path": data.path,
		"file_type": data.base_type,
		"track_type": data.track_type,
		"duration": data.duration,
		"node_name": data.name
	}
