extends Control

signal save_json(result_arr: Array)

@onready var json_row_scene = UIManager.get_desired_node("JsonRowV2")
@onready var rows_container = $VBoxContainer/ScrollContainer/RowsContainer

var word_popup: PopupPanel
var popup_edit_vbox: VBoxContainer
var current_editing_word = null

var current_zoom: float = 1.0
var show_confidence: bool = true

var add_word_popup: Window
var target_row_for_new_word = null


var l_data


func _ready():
	_create_floating_popup()
	_build_top_menu()


func _create_floating_popup():
	word_popup = PopupPanel.new()
	word_popup.size = Vector2(250, 120)
	add_child(word_popup)
	
	var main_v = VBoxContainer.new()
	word_popup.add_child(main_v)
	
	var close_btn = Button.new()
	close_btn.text = "x"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func(): word_popup.hide())
	main_v.add_child(close_btn)
	
	popup_edit_vbox = VBoxContainer.new()
	main_v.add_child(popup_edit_vbox)

	add_word_popup = Window.new()
	add_word_popup.title = "Add New Word"
	add_word_popup.size = Vector2(300, 200)
	add_word_popup.exclusive = true
	add_word_popup.visible = false
	add_word_popup.close_requested.connect(func(): add_word_popup.hide())
	add_child(add_word_popup)
	
	var v = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	add_word_popup.add_child(v)
	
	var edit_w = LineEdit.new(); edit_w.placeholder_text = "Word"
	var edit_s = LineEdit.new(); edit_s.placeholder_text = "Start (sec)"
	var edit_e = LineEdit.new(); edit_e.placeholder_text = "End (sec)"
	v.add_child(edit_w); v.add_child(edit_s); v.add_child(edit_e)
	
	var btn_add = Button.new()
	btn_add.text = "Add"
	btn_add.pressed.connect(func():
		if target_row_for_new_word:
			target_row_for_new_word.add_new_word(
				edit_w.text, 
				edit_s.text.to_float(), 
				edit_e.text.to_float()
			)
			add_word_popup.hide()
			edit_w.text = ""
	)
	v.add_child(btn_add)


func show_word_popup(word_block):
	current_editing_word = word_block
	for c in popup_edit_vbox.get_children(): 
		c.queue_free()
	
	var data = word_block.word_data
	
	# Используем новые стандартизированные названия полей для отображения в UI
	_add_popup_field("start_time", data)
	_add_popup_field("end_time", data)
	_add_popup_field("conf", data)
	
	var pos = word_block.global_position
	pos.y += word_block.size.y + 5
	word_popup.popup(Rect2(pos, word_popup.size))


func _add_popup_field(key, data):
	var h = HBoxContainer.new()
	var l = Label.new(); l.text = key + ":"; l.custom_minimum_size.x = 50
	var e = LineEdit.new(); e.text = str(data[key]); e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.text_changed.connect(func(new_val): if new_val.is_valid_float(): data[key] = new_val.to_float())
	h.add_child(l); h.add_child(e)
	popup_edit_vbox.add_child(h)


func open_add_word_dialog(row_node):
	target_row_for_new_word = row_node
	add_word_popup.popup_centered()


func _build_top_menu():
	var bar = HBoxContainer.new()
	$VBoxContainer.add_child(bar)
	$VBoxContainer.move_child(bar, 0)
	
	var save_btn = Button.new()
	save_btn.text = "💾 Save JSON"
	save_btn.pressed.connect(_on_save_pressed)
	bar.add_child(save_btn)
	
	var add_first = Button.new()
	add_first.text = "➕ Add line"
	add_first.pressed.connect(func(): _create_row({}, -1))
	bar.add_child(add_first)
	
	var conf_btn = CheckButton.new()
	conf_btn.text = "Highlight Vosk"
	conf_btn.button_pressed = true
	conf_btn.toggled.connect(_on_confidence_toggled)
	bar.add_child(conf_btn)

func _on_save_pressed():
	var data = get_final_json()
	print("--- JSON ---")
	print(JSON.stringify(data, "\t"))
	# var file = FileAccess.open("user://output.json", FileAccess.WRITE)
	# file.store_string(JSON.stringify(data))


func visualize(data: Array):
	for c in rows_container.get_children(): c.queue_free()
	
	l_data = data
	if data.is_empty(): return
		
	for d in data: 
		_create_row(d, -1)


func _create_row(data, index):
	var row = json_row_scene.instantiate()
	if index == -1: rows_container.add_child(row)
	else: 
		rows_container.add_child(row)
		rows_container.move_child(row, index)
		
	row.init(data, current_zoom, show_confidence)
	row.request_add_row_after.connect(_on_add_after)
	row.request_delete_row.connect(func(r): r.queue_free())
	return row


func _on_add_after(target_row):
	_create_row({}, target_row.get_index() + 1)


func _on_confidence_toggled(v):
	show_confidence = v
	for r in rows_container.get_children(): r.set_confidence_mode(v)


func _input(event):
	if event is InputEventKey and event.pressed and Input.is_key_pressed(KEY_CTRL):
		if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS: _apply_zoom(0.1)
		elif event.keycode == KEY_MINUS: _apply_zoom(-0.1)


func _apply_zoom(delta):
	current_zoom = clamp(current_zoom + delta, 0.5, 3.0)
	for r in rows_container.get_children(): r.apply_zoom(current_zoom)


func get_final_json() -> Array:
	var result_array = []
	for r in rows_container.get_children():
		if r.is_queued_for_deletion(): continue
		
		# Безопасное получение персонажа из Узла (Node)
		var row_char = "all"
		if "character" in r and r.character != "":
			row_char = r.character
		
		# Новая эталонная структура строки
		var line = {
			"character": row_char,
			"is_extended": false,
			"text": "", 
			"start_time": 0.0, 
			"end_time": 0.0, 
			"words": []
		}
		
		for w in r.words_container.get_children():
			var wd = w.word_data
			# ВАЖНО: wd - это Dictionary, поэтому здесь get с двумя аргументами работает отлично!
			var final_word = {
				"word": wd.get("word", ""),
				"start_time": wd.get("start_time", wd.get("start", 0.0)),
				"end_time": wd.get("end_time", wd.get("end", 0.0)),
				"conf": wd.get("conf", 1.0),
				"character": wd.get("character", "")
			}
			line["words"].append(final_word)
			line["text"] += final_word["word"] + " "
			
		line["text"] = line["text"].strip_edges()
		
		# Фиксируем общее время строки
		if line["words"].size() > 0: 
			line["start_time"] = line["words"][0]["start_time"]
			line["end_time"] = line["words"][-1]["end_time"]
			result_array.append(line)
			
	return result_array


func _on_save_btn_pressed() -> void:
	save_json.emit(get_final_json())


func _on_clipboard_btn_pressed() -> void:
	DisplayServer.clipboard_set(str(get_final_json()))
