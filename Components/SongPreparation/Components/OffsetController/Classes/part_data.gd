# part_data.gd
extends Node
class_name PartData
var context_menu = ContextMenuManager.new()

var uuid: String
var start_time: float
var end_time: float
var resource_path: String

func add_uuid(imported_uuid) -> void:
	uuid = imported_uuid


func _init(p_start_time: float, p_end_time: float, p_path: String):
	start_time = p_start_time
	end_time = p_end_time
	resource_path = p_path


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		context_menu.show_menu(get_viewport().get_mouse_position(), ["go to", "split", "copy", "delete"], func(id):
			match id:
				0: print("go to")
				1: print("split")
				2: print("copy")
				3: print("delete")
		)
