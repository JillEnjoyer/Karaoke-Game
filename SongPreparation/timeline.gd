extends Control

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer
@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames
@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines
@onready var h_scroll = $HSplitContainer/TimelinePanel/HScrollBar
@onready var v_scroll = $VScrollBar
@onready var name_panel = $HSplitContainer/NamePanel

var timeline_panel_scene = preload("res://SongPreparation/Components/TimeLinePanel/timeline_panel.tscn")

var character_names = ["Alex", "Samantha", "Jordan", "Christopher", "Taylor", "Morgan", "Jamie", "Alexander"]
var media_durations = [377, 20, 15, 25, 30, 12, 18, 22]

func _ready():
	var max_name_width = 0
	var font = ThemeDB.fallback_font

	for name in character_names:
		var text_width = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		max_name_width = max(max_name_width, text_width)

	name_panel.custom_minimum_size.x = max_name_width + 20
	
	for i in range(character_names.size()):
		add_character(character_names[i], media_durations[i])

	name_scroll_container.set_v_scroll(0)
	timeline_scroll_container.set_v_scroll(0)

	h_scroll.value_changed.connect(_on_h_scrollbar_value_changed)
	v_scroll.value_changed.connect(_on_v_scrollbar_value_changed)

	update_scrollbars()

func add_character(name: String, duration: int):
	var name_box = PanelContainer.new()
	name_box.custom_minimum_size = Vector2(name_panel.custom_minimum_size.x, 50)

	var name_label = Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_box.add_child(name_label)
	vbox_names.add_child(name_box)

	var timeline_box = timeline_panel_scene.instantiate()
	timeline_box.length_in_sec = duration
	timeline_box.length_convert()
	vbox_timelines.add_child(timeline_box)

func update_scrollbars():
	await get_tree().process_frame
	v_scroll.max_value = max(0, vbox_names.get_combined_minimum_size().y - name_scroll_container.size.y)

func _on_v_scrollbar_value_changed(value):
	name_scroll_container.set_v_scroll(value)
	timeline_scroll_container.set_v_scroll(value)

func _on_h_scrollbar_value_changed(value):
	timeline_scroll_container.set_h_scroll(value)
