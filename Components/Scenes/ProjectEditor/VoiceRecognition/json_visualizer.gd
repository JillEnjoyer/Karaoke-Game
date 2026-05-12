extends Control

@onready var json_row_scene = UIManager.get_desired_node("JsonRow")
@onready var rows_container = $VBoxContainer/ScrollContainer/RowsContainer

var flat_rows_list: Array = []
var selected_rows: Array = []
var last_interacted_row_index: int = -1
var characters = ["Alastor", "Charlie", "Vaggie"]


var technical_keys = ["start", "end", "conf", "duration", "result", "words"]

func _ready():
	var test_data = [
		{
			"text": "welcome home",
			"result": [
				{ "conf": 0.93, "start": 0.66, "end": 2.04, "word": "welcome" },
				{ "conf": 0.99, "start": 2.04, "end": 2.93, "word": "home" }
			]
		},
		{
			"text": "another phrase here",
			"result": [
				{ "conf": 0.88, "start": 3.0, "end": 3.5, "word": "another" }
			]
		}
	]
	visualize(test_data)

func visualize(data):
	for child in rows_container.get_children():
		child.queue_free()
	flat_rows_list.clear()
	selected_rows.clear()
	_build_recursive(data, rows_container)
	_update_row_indices()

func _build_recursive(data, parent_node):
	if data is Dictionary:
		for key in data:
			var val = data[key]
			var row = _create_row(key, val, parent_node)
			if val is Dictionary or val is Array:
				_build_recursive(val, row.children_container)
	elif data is Array:
		for i in range(data.size()):
			var val = data[i]
			var row = _create_row(str(i), val, parent_node)
			if val is Dictionary or val is Array:
				_build_recursive(val, row.children_container)

func _create_row(key, val, parent):
	var row = json_row_scene.instantiate()
	parent.add_child(row)
	
	var is_tech = (str(key) in technical_keys) or (val is float) or (val is int)
	var show_char_selector = !is_tech and not (val is Array or val is Dictionary)
	var is_readonly = (str(key) == "conf")
	
	row.init(key, val, characters, show_char_selector, is_readonly)
	flat_rows_list.append(row)
	
	row.row_selected.connect(_on_row_selected)
	row.character_changed.connect(_on_row_char_changed)
	row.dropped_on.connect(_on_rows_dropped)
	
	return row

func _update_row_indices():
	for i in range(flat_rows_list.size()):
		flat_rows_list[i].row_index = i


func _on_row_selected(row, is_ctrl_pressed):
	if is_ctrl_pressed:
		if last_interacted_row_index != -1:
			_select_range(last_interacted_row_index, row.row_index)
		else:
			_toggle_selection(row)
	else:
		deselect_all()
		_select_one(row)
	
	last_interacted_row_index = row.row_index

func _select_one(row):
	if row not in selected_rows:
		selected_rows.append(row)
		row.set_selected(true)

func _toggle_selection(row):
	if row in selected_rows:
		selected_rows.erase(row)
		row.set_selected(false)
	else:
		selected_rows.append(row)
		row.set_selected(true)

func _select_range(start_idx, end_idx):
	var min_i = min(start_idx, end_idx)
	var max_i = max(start_idx, end_idx)
	for i in range(min_i, max_i + 1):
		_select_one(flat_rows_list[i])

func deselect_all():
	for r in selected_rows:
		r.set_selected(false)
	selected_rows.clear()
	last_interacted_row_index = -1


func get_dragged_rows(initiator_row):
	# If we drag a row that is not currently selected, we should select only it before dragging
	if initiator_row not in selected_rows:
		deselect_all()
		_select_one(initiator_row)

	return selected_rows.duplicate()

func _on_rows_dropped(dragged_rows, target_row):
	for row in dragged_rows:
		if row == target_row or target_row.is_ancestor_of(row):
			continue
		
		row.get_parent().remove_child(row)
		target_row.children_container.add_child(row)
		
	target_row.children_container.visible = true
	target_row.fold_button.text = "v"
	
	_recalculate_array_keys(target_row)
	
	flat_rows_list.clear()
	_rebuild_flat_list(rows_container)
	_update_row_indices()
	print("Rows moved successfully!")

func _recalculate_array_keys(parent_row):
	if parent_row.my_data_ref is Array:
		var idx = 0
		for child in parent_row.children_container.get_children():
			child.key_label.text = str(idx)
			idx += 1

func _rebuild_flat_list(node):
	for child in node.get_children():
		if child.has_method("init"):
			flat_rows_list.append(child)
			if child.is_container:
				_rebuild_flat_list(child.children_container)


func _on_row_char_changed(trigger_row, new_idx):
	if trigger_row in selected_rows:
		for row in selected_rows:
			if row != trigger_row and row.char_selector.visible:
				row.char_selector.selected = new_idx

func get_final_json() -> Variant:
	var final_data
	if flat_rows_list.size() > 0:
		var roots = rows_container.get_children()
		if roots.size() > 0 and roots[0].key_label.text.is_valid_int():
			final_data = []
			for root in roots:
				final_data.append(root.get_reconstructed_data())
		else:
			final_data = {}
			for root in roots:
				final_data[root.key_label.text] = root.get_reconstructed_data()
	return final_data

func _on_button_pressed() -> void:
	var final_data = get_final_json()
	print("Final JSON:\n", JSON.stringify(final_data, "\t"))
