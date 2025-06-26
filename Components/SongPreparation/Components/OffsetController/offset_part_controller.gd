#offset_controller.gd
extends Control
signal offset_changed(new_offset)
signal trim_changed(start_offset, end_offset)

@export var node_name := ""
@export var initial_path := ""
@export var node_type := ""
@export var total_duration: float = 240.0
@export var start_offset: float = 0.0
@export var end_offset: float = 0.0


var uuid: String
var start_time: float
var end_time: float
var resource_path: String


var thumbnail_generator = ThumbnailGenerator.new()
var waveform_generator = WaveformGenerator.new()
var context_menu = ContextMenuManager.new()
var dot_drawer = ""

var ffmpeg_path = PreferencesData.getExtPath("ffmpeg")

var dragging_left := false
var dragging_right := false
var initial_mouse_x := 0.0
var initial_offset := 0.0

var is_dragging_track := false
var drag_start_position := Vector2()
var initial_track_offset := 0.0

@onready var thumb_container := $ThumbnailContainer
@onready var drag_btn := $DragBtn
@onready var left_handle := $LeftHandle
@onready var right_handle := $RightHandle
@onready var thumbnails_container := $ThumbnailContainer/HBoxContainer
var timestamp = 5

func _ready():
	import_initial_data(node_type, initial_path)
	drag_btn.button_down.connect(_start_drag)
	drag_btn.button_up.connect(_end_drag)
	
	add_child(context_menu)


func add_uuid(imported_uuid) -> void:
	uuid = imported_uuid


func init(p_start_time: float, p_end_time: float, p_path: String):
	start_time = p_start_time
	end_time = p_end_time
	resource_path = p_path


func _start_drag():
	is_dragging_track = true
	drag_start_position = get_global_mouse_position()
	initial_track_offset = position.x


func _end_drag():
	is_dragging_track = false


func import_initial_data(type: String, path: String):
	if type == "video":
		create_thumbnails(path)
	elif type == "audio":
		create_waveform(path)
	elif type == "subtitles":
		draw_dots()


func create_thumbnails(path: String):
	setup_needed_width(total_duration)
	print(self.size.x)
	print(self.size.y)
	
	var data = thumbnail_generator.generate_thumbnails(path, self.size.x, self.size.y)
	var textures = data.get("thumbnails", [])

	for child in thumbnails_container.get_children():
		child.queue_free()
	
	for texture in textures:
		var tex_rect = TextureRect.new()
		tex_rect.texture = texture
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		thumbnails_container.add_child(tex_rect)


func create_waveform(path: String):
	setup_needed_width(total_duration)
	print(self.size.x)
	print(self.size.y)
	
	for child in thumbnails_container.get_children():
		child.queue_free()
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = waveform_generator.load_waveform_image(path, ffmpeg_path, self.size.x, self.size.y, "black")
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	thumbnails_container.add_child(tex_rect)


func draw_dots():
	pass


func update_range_rect():
	var visible_width = size.x * (1.0 - (start_offset + end_offset) / total_duration)
	thumb_container.size.x = visible_width
	left_handle.position.x = 0
	right_handle.position.x = visible_width - right_handle.size.x


func setup_needed_width(duration: int):
	self.custom_minimum_size.x = ceil(duration / timestamp) * (70.0 * 16.0 / 9.0)
	self.size.x = self.custom_minimum_size.x


func _on_left_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_left = true
			initial_mouse_x = get_global_mouse_position().x
			initial_offset = start_offset
		else:
			dragging_left = false
	
	if dragging_left and event is InputEventMouseMotion:
		var delta = get_global_mouse_position().x - initial_mouse_x
		start_offset = clamp(initial_offset + (delta / size.x) * total_duration, 0, total_duration - end_offset)
		update_range_rect()
		emit_signal("trim_changed", start_offset, end_offset)


func _on_right_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_right = true
			initial_mouse_x = get_global_mouse_position().x
			initial_offset = end_offset
		else:
			dragging_right = false
	
	if dragging_right and event is InputEventMouseMotion:
		var delta = get_global_mouse_position().x - initial_mouse_x
		end_offset = clamp(initial_offset - (delta / size.x) * total_duration, 0, total_duration - start_offset)
		update_range_rect()
		emit_signal("trim_changed", start_offset, end_offset)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_dragging_track:
			Debugger.debug("change position")
			var drag_delta = event.global_position.x - drag_start_position.x
			var new_offset = initial_track_offset + drag_delta
			new_offset = clamp(new_offset, 0, get_parent().size.x - size.x)

			Debugger.debug("offset_changed = " + str(new_offset))
			emit_signal("offset_changed", new_offset, get_parent())

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		context_menu.show_menu(
			get_viewport().get_mouse_position(),
			["go to", "split", "copy", "delete"],
			func(id):
				match id:
					0: print("go to")
					1: print("split")
					2: print("copy")
					3: print("delete")
		)



func _on_drag_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		context_menu.show_menu(
			get_viewport().get_mouse_position(),
			["go to", "split", "copy", "delete"],
			func(id):
				match id:
					0: print("go to")
					1: print("split")
					2: print("copy")
					3: print("delete")
		)
