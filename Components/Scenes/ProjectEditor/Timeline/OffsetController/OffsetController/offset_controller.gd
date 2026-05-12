#offset_controller.gd
extends Control

# required signals:
signal request_split(segment_id, at_time) # request to split the segment at the given time
signal request_delete(node) # request to delete the segment
signal request_copy(node) # request to copy the segment
signal request_go_to(node, position) # request to go to the segment
signal position_changed() # signal for segment position change
signal size_changed() # signal for segment size change
signal segment_size_changed(segment_id)

var context_menu = ContextMenuManager.new()
@onready var wrapper = $"../../ControllerWrapper"
@onready var thumb_container := $ThumbnailContainer
@onready var drag_btn := $DragBtn
@onready var left_handle := $LeftHandle
@onready var right_handle := $RightHandle
@onready var thumbnails_container := $ThumbnailContainer/HBoxContainer

@onready var time_pointer := UIManager.find_scene_in_scene_tree("TimePointer")
@onready var scroll_container := UIManager.find_scene_in_scene_tree("ScrollContainer")

const timestamp = 5 # seconds per frame - can be changed by resize
const px_to_sec_ratio: float = (70.0 * 16.0 / 9.0) / timestamp

var resource_path: String

# core properties
var segment_id: int = -1 # is it neccessary?
var node_type := ""
var total_duration: float = 240.0 # duration of whole material - not always a segment

# media properties
var start_time: float = 0.0 # in seconds
var end_time: float = 0.0 # in seconds

# editor properties
var left_cutoff: float = 0.0 #px
var prev_left_cutoff := 0.0
var right_cutoff: float = 0.0 #px
var global_offset: float = 0.0 #px - only positive value (to the right)

var dragging_left := false
var dragging_right := false
var is_dragging_track := false

var initial_mouse_x := 0.0
var initial_left_cutoff := 0.0
var initial_right_cutoff := 0.0

var initial_pos_x := 0.0

var drag_start_position := Vector2()
var initial_track_offset := 0.0


func _ready():
	clip_contents = true
	add_child(context_menu)
	#drag_btn.gui_input.connect(_on_drag_btn_gui_input)


func apply_thumbnail_data(textures: Array, duration: float) -> void:
	total_duration = duration
	setup_needed_width(duration)

	for child in thumbnails_container.get_children():
		child.queue_free()
	
	for texture in textures:
		var tex_rect = TextureRect.new()
		tex_rect.texture = texture
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		thumbnails_container.add_child(tex_rect)
	
	update_range_rect()


func _start_drag():
	is_dragging_track = true
	drag_start_position = get_global_mouse_position()
	initial_track_offset = position.x

"""
func _end_drag():
	is_dragging_track = false
"""
func _end_drag():
	is_dragging_track = false
	dragging_left = false
	dragging_right = false

	# Signal to parent that position changed
	# Call deferred to avoid conflicts during input processing
	if get_parent().has_method("_resolve_conflicts"):
		get_parent().call_deferred("_resolve_conflicts")

"""
func update_range_rect():
	var visible_width = size.x * (1.0 - (left_cutoff + right_cutoff) / total_duration) # Visible width of the segment
	Debugger.debug("visible_width = " + str(visible_width) + "\nDrawn thumbs size = " + str(thumb_container.size.x))

	#custom_minimum_size.x = visible_width
	#size.x = visible_width * 2.0
	thumb_container.size.x = visible_width
	#thumb_container.size.x = visible_width
	
	left_handle.position.x = 0
	right_handle.position.x = visible_width - right_handle.size.x

	emit_signal("size_changed") # Notify parent about size change to update wrapper size
"""
func update_range_rect():
	# How much duration is visible after applying cutoffs
	var visible_duration = total_duration - left_cutoff - right_cutoff

	var visible_width = visible_duration * px_to_sec_ratio

	self.custom_minimum_size.x = visible_width
	self.size.x = visible_width

	# thats block of thumbnails we show
	thumb_container.position.x = -(left_cutoff * px_to_sec_ratio)

	left_handle.position.x = 0
	right_handle.position.x = visible_width - right_handle.size.x

	emit_signal("size_changed")


func setup_needed_width(duration: float):
	self.custom_minimum_size.x = ceil(duration * px_to_sec_ratio)
	self.size.x = self.custom_minimum_size.x
	thumb_container.size.x = self.size.x
	wrapper.custom_minimum_size.x = self.size.x
	#emit_signal("segment_size_changed", segment_id)


func _on_left_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_left = true
			initial_mouse_x = get_global_mouse_position().x
			initial_left_cutoff = left_cutoff
			initial_pos_x = position.x

			#prev_left_cutoff = left_cutoff
		else:
			dragging_left = false
			if get_parent().has_method("_resolve_conflicts"):
				get_parent().call_deferred("_resolve_conflicts")

	if dragging_left and event is InputEventMouseMotion:
		var delta_px = get_global_mouse_position().x - initial_mouse_x
		var delta_sec = delta_px / px_to_sec_ratio

		var new_left_cutoff = clamp(initial_left_cutoff + delta_sec, 0.0, total_duration - right_cutoff)
		
		# check if cutoff changed (clamp may not change it)
		if new_left_cutoff != left_cutoff:
			left_cutoff = new_left_cutoff

			var actual_delta_sec = new_left_cutoff - initial_left_cutoff
			var actual_shift_px = actual_delta_sec * px_to_sec_ratio
			
			position.x = initial_pos_x + actual_shift_px
			
			update_range_rect()
		## ----------------------
		"""var new_left_cutoff = clamp(initial_left_cutoff + (delta_px / size.x) * total_duration, 0, total_duration - right_cutoff)
		var offset_delta = new_left_cutoff - left_cutoff
		left_cutoff = new_left_cutoff
		position.x += offset_delta * (size.x / total_duration)
		update_range_rect()
		prev_left_cutoff = left_cutoff"""


func _on_right_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_right = true
			initial_mouse_x = get_global_mouse_position().x
			initial_right_cutoff = right_cutoff
		else:
			dragging_right = false
			if get_parent().has_method("_resolve_conflicts"):
				get_parent().call_deferred("_resolve_conflicts")
	
	if dragging_right and event is InputEventMouseMotion:
		var delta_px = get_global_mouse_position().x - initial_mouse_x

		var delta_sec = delta_px / px_to_sec_ratio

		# Important: Moving mouse to the right should decrease right_cutoff (increase visual segment size)
		var new_right_cutoff = clamp(initial_right_cutoff - delta_sec, 0.0, total_duration - left_cutoff)
		
		right_cutoff = new_right_cutoff
		update_range_rect()
	"""if dragging_right and event is InputEventMouseMotion:
		var delta = get_global_mouse_position().x - initial_mouse_x
		right_cutoff = clamp(initial_right_cutoff - (delta / size.x) * total_duration, 0, total_duration - left_cutoff)
		update_range_rect()"""

"""
func _on_drag_btn_gui_input(event: InputEvent) -> void:
	var new_offset: float = 0.0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		wrapper.size.x = wrapper.size.x + 1000.0 # if right handle is closer than 1000px from the right edge - expand the wrapper. After finishing, compress it again.
		if is_dragging_track and event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			var drag_delta = mm.global_position.x - drag_start_position.x
			new_offset = initial_track_offset + drag_delta
			new_offset = clamp(new_offset, 0.0, get_parent().size.x - size.x)
			position.x = new_offset
			emit_signal("position_changed")
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_show_context_menu()
"""
func _on_drag_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			else:
				_end_drag()
				# After dragging ends restore wrapper size
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu()

	if is_dragging_track and event is InputEventMouseMotion:
		var drag_delta = event.global_position.x - drag_start_position.x
		var new_x = initial_track_offset + drag_delta
		
		new_x = max(0.0, new_x)
		
		# Snapping could be added here
		position.x = new_x
		
		emit_signal("position_changed")


func _show_context_menu():
	context_menu.show_menu(
		get_viewport().get_mouse_position(),
		["go to", "split", "copy", "delete"],
		func(id):
			match id:
				0:
					# We move to exact start of segment
					emit_signal("request_go_to", self, self.position.x)
				1:
					var cut_time = time_pointer.pointer_position_in_px + scroll_container.scroll_horizontal
					emit_signal("request_split", self, cut_time)
				2:
					# copying segment and pasting it at right
					emit_signal("request_copy", self)
				3:
					emit_signal("request_delete", self)
	)
