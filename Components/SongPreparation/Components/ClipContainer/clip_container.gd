#clip_container.gd
extends Control

var full_thumbnails := {}
var offset_controllers := []
var time_scale := 100.0


func _ready():
	pass


func _init(desired_size_x: float = 300.0, desired_position_x: float = 0.0) -> void:
	self.size = Vector2(desired_position_x + 1000.0, 70.0)
	self.position = Vector2(desired_position_x, 0.0)



func init(desired_size_x: float = 300.0, desired_position_x: float = 0.0) -> void:
	self.size = Vector2(desired_position_x + 1000.0, 70.0)
	self.position = Vector2(desired_position_x, 0.0)



func add_clip(start_time: float, end_time: float):
	var offset = UIManager.get_desired_node("offset_controller").instantiate()
	offset.start_offset = start_time
	offset.end_offset = end_time
	offset.total_duration = end_time - start_time

	# Provide reference to full thumbnails (shared!)
	offset.thumbnail_generator.set_thumbnails(full_thumbnails)
	
	UIManager.new_child(offset, self)
	offset.rect_position.x = time_to_position(start_time)
	offset.rect_size.x = time_to_position(end_time - start_time)

	offset_controllers.append(offset)


func split_clip(target_offset: Node, cut_time: float):
	var start_time = target_offset.start_offset
	var end_time = target_offset.end_offset

	if cut_time <= start_time or cut_time >= end_time:
		Debugger.error("Invalid cut time")
		return

	# Remove old offset
	offset_controllers.erase(target_offset)
	remove_child(target_offset)
	target_offset.queue_free()

	# Calculate proportions
	var left_duration = cut_time - start_time
	var right_duration = end_time - cut_time

	# Add new offset controllers
	add_clip(start_time, cut_time)
	add_clip(cut_time, end_time)


func time_to_position(t: float) -> float:
	return t * time_scale


func position_to_time(x: float) -> float:
	return x / time_scale
