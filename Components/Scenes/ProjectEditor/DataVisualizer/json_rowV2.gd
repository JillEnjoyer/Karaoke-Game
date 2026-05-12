extends PanelContainer

signal request_add_row_after(row_node)
signal request_delete_row(row_node)

var main_hbox: HBoxContainer
var content_vbox: VBoxContainer
var words_container: HFlowContainer
var right_tools: VBoxContainer

var add_btn: Button
var del_btn: Button
var drag_handle: ColorRect

var row_menu: PopupMenu

var current_zoom: float = 1.0
var show_confidence: bool = true

func _ready():
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.x = 600
	
	for c in get_children():
		c.queue_free()
		
	main_hbox = HBoxContainer.new()
	add_child(main_hbox)

	drag_handle = ColorRect.new()
	drag_handle.color = Color(0.3, 0.3, 0.35)
	drag_handle.custom_minimum_size = Vector2(20, 0)
	main_hbox.add_child(drag_handle)
	
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(content_vbox)
	
	words_container = HFlowContainer.new()
	words_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(words_container)
	
	right_tools = VBoxContainer.new()
	right_tools.alignment = BoxContainer.ALIGNMENT_END
	main_hbox.add_child(right_tools)
	
	add_btn = Button.new()
	add_btn.text = "+"
	add_btn.pressed.connect(func(): emit_signal("request_add_row_after", self))
	right_tools.add_child(add_btn)
	
	del_btn = Button.new()
	del_btn.text = "-"
	del_btn.modulate = Color(1, 0.4, 0.4)
	del_btn.pressed.connect(func(): emit_signal("request_delete_row", self))
	right_tools.add_child(del_btn)

	row_menu = PopupMenu.new()
	row_menu.add_item("Add word")
	row_menu.id_pressed.connect(_on_row_menu_id_pressed)
	add_child(row_menu)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		row_menu.position = get_global_mouse_position()
		row_menu.popup()

func _on_row_menu_id_pressed(id):
	if id == 0:
		var visualizer = get_tree().current_scene
		if visualizer.has_method("open_add_word_dialog"):
			visualizer.open_add_word_dialog(self)

func add_new_word(word_text: String, start_t: float, end_t: float):
	var new_data = {
		"word": word_text,
		"start": start_t,
		"end": end_t,
		"conf": 1.0
	}
	var word_block = WordBlock.new(new_data, self)
	words_container.add_child(word_block)
	word_block.apply_zoom(current_zoom)

func init(phrase_data: Dictionary = {}, zoom: float = 1.0, use_conf: bool = true):
	current_zoom = zoom
	show_confidence = use_conf
	if phrase_data.has("result"):
		for word_dict in phrase_data["result"]:
			var word_block = WordBlock.new(word_dict, self)
			words_container.add_child(word_block)
	apply_zoom(current_zoom)

func apply_zoom(zoom_factor: float):
	current_zoom = zoom_factor
	drag_handle.custom_minimum_size.x = 20 * zoom_factor
	for word in words_container.get_children():
		word.apply_zoom(zoom_factor)

func set_confidence_mode(is_on: bool):
	show_confidence = is_on
	for word in words_container.get_children():
		word._update_color()


func _can_drop_data(_at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.get("type") in ["word", "line"]

func _drop_data(_at_position, data):
	if data["type"] == "line":
		get_parent().move_child(data["node"], get_index())
		
	elif data["type"] == "word":
		var source_word = data["node"]
		var old_row = source_word.row_node
		
		source_word.get_parent().remove_child(source_word)

		words_container.add_child(source_word)

		source_word.row_node = self
		
		if old_row.words_container.get_child_count() == 0:
			old_row.queue_free()


class WordBlock extends PanelContainer:
	var word_data: Dictionary
	var row_node
	var label: Label
	var style_box: StyleBoxFlat
	var word_menu: PopupMenu
	
	func _init(data, p_row):
		word_data = data
		row_node = p_row
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		style_box = StyleBoxFlat.new()
		style_box.set_corner_radius_all(4)
		add_theme_stylebox_override("panel", style_box)
		
		label = Label.new()
		label.text = str(word_data.get("word", ""))
		add_child(label)
		
		word_menu = PopupMenu.new()
		word_menu.add_item("Delete word")
		word_menu.id_pressed.connect(_on_menu_pressed)
		add_child(word_menu)
		
		_update_color()


	func _get_drag_data(_at_position):
		if Input.is_key_pressed(KEY_CTRL):
			var preview = Label.new()
			preview.text = label.text
			preview.modulate = Color(1, 1, 1, 0.7) 
			set_drag_preview(preview)
			return {"type": "word", "node": self}
		return null

	func _can_drop_data(_at_position, data):
		return typeof(data) == TYPE_DICTIONARY and data.get("type") == "word"

	func _drop_data(_at_position, data):
		var source_word = data["node"]
		var old_row = source_word.row_node
		
		var target_container = get_parent() 
		source_word.get_parent().remove_child(source_word)
		target_container.add_child(source_word)
		
		target_container.move_child(source_word, get_index())
		
		source_word.row_node = self.row_node
		
		if old_row.words_container.get_child_count() == 0:
			old_row.queue_free()

	func _gui_input(event):
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not Input.is_key_pressed(KEY_CTRL):
					var visualizer = row_node.get_parent().get_parent().get_parent().get_parent()
					if visualizer.has_method("show_word_popup"):
						visualizer.show_word_popup(self)
						accept_event()
				else:
					#  _get_drag_data
					pass
					
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				word_menu.position = get_global_mouse_position()
				word_menu.popup()
				accept_event()

	func _on_menu_pressed(id):
		if id == 0:
			var p = get_parent()
			self.queue_free()
			await row_node.get_tree().process_frame
			if p.get_child_count() == 0:
				row_node.queue_free()

	func apply_zoom(zoom: float):
		label.add_theme_font_size_override("font_size", int(16 * zoom))
		style_box.content_margin_left = 8 * zoom
		style_box.content_margin_right = 8 * zoom
		style_box.content_margin_top = 4 * zoom
		style_box.content_margin_bottom = 4 * zoom

	func _update_color():
		if not row_node.show_confidence:
			style_box.bg_color = Color(0.3, 0.3, 0.35)
			return
		var conf = float(word_data.get("conf", 1.0))
		if conf >= 0.9: style_box.bg_color = Color(0.2, 0.6, 0.2)
		elif conf >= 0.7: style_box.bg_color = Color(0.7, 0.6, 0.1)
		else: style_box.bg_color = Color(0.7, 0.2, 0.2)
