extends Control

@onready var DragBtn = $DragBtn

var is_dragging := false
var drag_start_mouse_x := 0.0
var drag_start_position_x := 0.0

func _ready():
	DragBtn.connect("gui_input", _on_DragBtn_gui_input)


func _on_DragBtn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_mouse_x = get_global_mouse_position().x
			drag_start_position_x = position.x
		else:
			is_dragging = false
	
	elif is_dragging and event is InputEventMouseMotion:
		var mouse_delta_x = get_global_mouse_position().x - drag_start_mouse_x
		position.x = drag_start_position_x + mouse_delta_x
