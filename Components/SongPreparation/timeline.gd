#timeline.gd
extends Control

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer
@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames
@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines
@onready var h_scroll = $HSplitContainer/TimelinePanel/TimeBar/HScrollBar
@onready var v_scroll = $VScrollBar
@onready var name_panel = $HSplitContainer/NamePanel

@onready var time_lbl_start = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelStart
@onready var time_lbl_end = $HSplitContainer/TimelinePanel/TimeBar/TimeLabelEnd

var track_initial_widths = {}

var tracks_info: Array = [ #0, 1, 2 pos...if 0 is deleted then others shold move down
	
]
var track_example: Dictionary = {
	"path": "",
	"type": "", # Video/Instrumental/Acapella/Character
	"initial_width": {},# "1": ...
	"parts": {}
}
var part_example: Dictionary = {
	"start_time": 0.0,
	"end_time": 0.0,
}


const PartData = preload("res://Components/SongPreparation/Components/OffsetController/Classes/part_data.gd")
const TrackData = preload("res://Components/SongPreparation/Components/OffsetController/Classes/track_data.gd")


func _ready():
	var max_name_width = 0
	var font = ThemeDB.fallback_font

	name_panel.custom_minimum_size.x = max_name_width + 20
	
	name_scroll_container.set_v_scroll(0)
	timeline_scroll_container.set_v_scroll(0)

	h_scroll.value_changed.connect(_on_h_scrollbar_value_changed)
	v_scroll.value_changed.connect(_on_v_scrollbar_value_changed)

	update_scrollbars()
	
	update_time_labels()
	update_scroll_range()


func update_time_labels():
	var start_time = h_scroll.value
	var end_time = h_scroll.value + visible_time_range()
	
	time_lbl_start.text = _format_time(start_time)
	time_lbl_end.text = _format_time(end_time)


func _format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var sec = int(seconds) % 60
	return "%02d:%02d" % [minutes, sec]


func visible_time_range() -> float:
	# Возвращает видимый диапазон времени
	return timeline_scroll_container.size.x / pixels_per_second()


func pixels_per_second() -> float:
	# Количество пикселей на секунду (настроить под ваш проект)
	return 50.0


func update_scroll_range():
	# Устанавливаем диапазон скролла
	var total_width = vbox_timelines.get_combined_minimum_size().x
	var visible_width = timeline_scroll_container.size.x
	h_scroll.max_value = max(0, total_width - visible_width)
	h_scroll.page = visible_width


func _on_h_scroll_changed(value: float):
	timeline_scroll_container.scroll_horizontal = value
	update_time_labels()


func add_character(node_name: String, path: String, duration: int):
	var name_box = PanelContainer.new()
	name_box.custom_minimum_size = Vector2(name_panel.custom_minimum_size.x, 50)

	var name_label = Label.new()
	name_label.text = node_name
	name_label.size_flags_horizontal = Control.SIZE_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(100, 70)
	name_box.add_child(name_label)
	vbox_names.add_child(name_box)

	var offset_controller = UIManager.get_desired_node("off_con_part").instantiate()
	offset_controller.node_name = node_name
	offset_controller.initial_path = path
	offset_controller.node_type = node_name
	offset_controller.total_duration = duration
	#offset_controller.start_offset = 0.0
	#offset_controller.end_offset = 0.0
	
	# Создаём Control-обёртку
	var track_container = Control.new()
	track_container.custom_minimum_size = Vector2(0, 70)
	track_container.size_flags_vertical = Control.SIZE_FILL
	
	track_container.add_child(offset_controller)
	vbox_timelines.add_child(track_container)
	
	track_initial_widths[track_container] = offset_controller.size.x
	#vbox_timelines.add_child(offset_controller)
	
	offset_controller.offset_changed.connect(_on_position_changed)
	offset_controller.trim_changed.connect(_on_trim_changed.bind(track_container))
	
	update_time_labels()
	update_scroll_range()


func _on_position_changed(new_x: float, track_container: Control):
	track_container.position.x = new_x
	track_container.custom_minimum_size.x = new_x + track_initial_widths[track_container]
	vbox_timelines.queue_sort()


func _on_trim_changed(start_trim: float, end_trim: float, track_container: Control):
	var offset_ctrl = track_container.get_child(0)
	var trim_width = (start_trim + end_trim) / offset_ctrl.total_duration * track_initial_widths[track_container]
	
	# Корректируем размер прослойки
	track_container.custom_minimum_size.x = track_initial_widths[track_container] - trim_width
	offset_ctrl.size.x = track_container.custom_minimum_size.x
	
	# Сдвигаем содержимое внутри прослойки
	offset_ctrl.position.x = start_trim / offset_ctrl.total_duration * track_initial_widths[track_container]
	vbox_timelines.queue_sort()


func _on_offset_changed(delta_offset: float, track_container: Control):
	print(delta_offset)
	track_container.position.x += delta_offset
	if track_container.position.x < 0:
		track_container.position.x = 0
	vbox_timelines.queue_sort()


func update_scrollbars():
	await get_tree().process_frame
	v_scroll.max_value = max(0, vbox_names.get_combined_minimum_size().y - name_scroll_container.size.y)
	h_scroll.max_value = max(0, vbox_timelines.get_combined_minimum_size().x - name_scroll_container.size.x)


func _on_v_scrollbar_value_changed(value):
	name_scroll_container.set_v_scroll(value)
	timeline_scroll_container.set_v_scroll(value)
func _on_h_scrollbar_value_changed(value):
	timeline_scroll_container.set_h_scroll(value)

"""
chosen_files.append({
		"path": path,
		"type": type,
		"duration": duration
	})

chosen_files = [
	{"path": path, "type": type, "duration": duration},
	{"path": path, "type": type, "duration": duration}
]
"""

func import_choosen_files(files: Array):
	pass
	for file in files:
		add_character(file["type"], file["path"], file["duration"])
