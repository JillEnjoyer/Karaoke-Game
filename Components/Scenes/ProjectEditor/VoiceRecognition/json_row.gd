extends PanelContainer

signal row_selected(row, is_ctrl_pressed)
signal value_changed(row, new_value)
signal character_changed(row, new_char_index)
signal request_drag_data(row) # Ask controller for data to drag
signal dropped_on(dragged_rows, target_row)

@onready var selection_box = $MainLayout/Header/CheckBox
@onready var fold_button = $MainLayout/Header/FoldButton
@onready var key_label = $MainLayout/Header/KeyLabel
@onready var value_edit = $MainLayout/Header/ValueEdit
@onready var char_selector = $MainLayout/Header/CharSelector
@onready var children_container = $MainLayout/Indentation/ChildrenContainer
@onready var indentation = $MainLayout/Indentation

var my_data_ref
var is_container = false
var row_index: int = -1

var style_selected = StyleBoxFlat.new()
var style_normal = StyleBoxEmpty.new()

func _ready():
	style_selected.bg_color = Color(0.2, 0.4, 0.6, 0.5)
	fold_button.pressed.connect(_on_fold_pressed)
	selection_box.gui_input.connect(_on_checkbox_input)
	value_edit.text_changed.connect(func(new_text): emit_signal("value_changed", self, new_text))
	char_selector.item_selected.connect(func(idx): emit_signal("character_changed", self, idx))


func init(key, value, character_list: Array, show_char_selector: bool, is_readonly: bool):
	key_label.text = str(key)
	my_data_ref = value
	
	char_selector.clear()
	char_selector.add_item("None")
	for char_name in character_list:
		char_selector.add_item(char_name)

	if value is Dictionary or value is Array:
		is_container = true
		value_edit.visible = false
		fold_button.visible = true
		fold_button.text = "v"
		char_selector.visible = show_char_selector
	else:
		is_container = false
		value_edit.text = str(value)
		fold_button.visible = false
		indentation.visible = false
		char_selector.visible = show_char_selector
		
		if is_readonly:
			value_edit.editable = false
			value_edit.modulate = Color(1, 1, 1, 0.5)

func set_selected(is_active: bool):
	selection_box.button_pressed = is_active
	add_theme_stylebox_override("panel", style_selected if is_active else style_normal)

func _on_fold_pressed():
	children_container.visible = !children_container.visible
	fold_button.text = ">" if not children_container.visible else "v"

func _on_checkbox_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var is_ctrl = Input.is_key_pressed(KEY_CTRL)
		emit_signal("row_selected", self, is_ctrl)
		accept_event()


# --- DRAG & DROP ---
func _get_drag_data(_at_position):
	var controller = self
	while controller != null and not controller.has_method("get_dragged_rows"):
		controller = controller.get_parent()
	
	if controller == null:
		push_error("Failed to find visual controller!")
		return null

	var drag_data = controller.get_dragged_rows(self)
	
	var preview = Control.new()
	var preview_label = Label.new()
	preview_label.text = "📦 Object transfer " + str(drag_data.size())
	preview_label.modulate = Color(0.7, 0.9, 1.0)
	preview.add_child(preview_label)
	set_drag_preview(preview)
	
	return drag_data

func _can_drop_data(at_position, data):
	return is_container

func _drop_data(at_position, data):
	emit_signal("dropped_on", data, self)


# --- Saving ---
func get_reconstructed_data():
	if is_container:
		var new_data
		if my_data_ref is Dictionary:
			new_data = {}
			for child in children_container.get_children():
				var child_data = child.get_reconstructed_data()
				var child_key = child.key_label.text
				new_data[child_key] = child_data
				
				if child.char_selector.visible and child.char_selector.selected > 0:
					var char_name = child.char_selector.get_item_text(child.char_selector.selected)
					new_data[child_key + "_char"] = char_name
		else:
			new_data = []
			for child in children_container.get_children():
				new_data.append(child.get_reconstructed_data())
		return new_data
	else:
		var val = value_edit.text
		if val.is_valid_float(): return val.to_float()
		if val.is_valid_int(): return val.to_int()
		return val
