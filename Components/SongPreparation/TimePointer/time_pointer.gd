extends Control

signal pointer_moved(new_time)

@onready var DragBtn = $DragBtn
@onready var TimelinePanel = $"../../TimelinePanel"

var pointer_position: float = 0.0
var is_dragging := false
var drag_start_mouse_x := 0.0
var drag_start_position_x := 0.0

func _ready():
	await get_tree().process_frame
	DragBtn.connect("gui_input", _on_DragBtn_gui_input)


func _on_DragBtn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_mouse_x = get_global_mouse_position().x
			drag_start_position_x = position.x + size.x / 2
		else:
			is_dragging = false
	
	elif is_dragging and event is InputEventMouseMotion:
		var mouse_delta_x = get_global_mouse_position().x - drag_start_mouse_x
		var new_x = drag_start_position_x + mouse_delta_x

		var min_x = 0.0
		var max_x = TimelinePanel.size.x

		position.x = clamp(new_x, min_x, max_x) - size.x / 2
		pointer_position = TimelinePanel.px_to_time(position.x + size.x / 2)
		emit_signal("pointer_moved", pointer_position)
