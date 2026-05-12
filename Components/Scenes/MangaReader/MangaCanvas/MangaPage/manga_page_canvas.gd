## class that would be storing pages, will be moving them, zooming in on frames, etc.
extends Control

signal page_changed(current_page_num: int)

var page_scene = preload("uid://bxrs04c0ghjj2")
var pages_buffer = []
var current_page: TextureRect = null
var current_frame_idx: int = -1
var current_page_num: int = 0:
	set(value):
		if value != current_page_num:
			current_page_num = value
			page_changed.emit(current_page_num)

var is_transitioning := false

@onready var canvas_size = get_viewport().get_visible_rect().size


func next_step():
	if not current_page: 
		return

	var frames = []
	if "meta" in current_page and current_page.meta.has("frames"):
		frames = current_page.meta["frames"]

	var frames_count = frames.size()

	if current_frame_idx < frames_count - 1:
		current_frame_idx += 1
		focus_on_frame(current_frame_idx)
	else:
		transition_to_next_page()
		current_page_num += 1


func focus_on_frame(idx: int):
	var frame_center = current_page.get_frame_center(idx)
	var frame_size = current_page.get_frame_size(idx)

	var scale_x = canvas_size.x / frame_size.x
	var scale_y = canvas_size.y / frame_size.y
	var target_scale = min(scale_x, scale_y) * 0.9

	#Debugger.info("Focusing on frame " + str(idx) + ": center " + str(frame_center) + ", size " + str(frame_size) + ", target scale " + str(target_scale))

	var duration = 0.8
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)

	# 1. Move pivot to frame center, so that scaling and positioning will be relative to it
	tw.tween_property(current_page, "pivot_offset", frame_center, duration)
	# 2. Move page so that frame center is in the center of the screen. Since pivot is now at frame_center, we can just move page to (canvas_center - pivot)
	tw.tween_property(current_page, "position", (canvas_size / 2) - frame_center, duration)
	# 3. Scaling page so that frame fits the screen
	tw.tween_property(current_page, "scale", Vector2(target_scale, target_scale), duration)

	# 4. remove mask
	current_page.reveal_frame(idx, duration)


func transition_to_previous_page():
	pass


func transition_to_next_page():
	if is_transitioning:
		return
	if pages_buffer.size() < 2:
		return

	is_transitioning = true
	var duration = 0.8
	var next_page = pages_buffer[1]
	next_page.visible = true

	var tw_prep = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	
	var scale_curr = canvas_size.x / current_page.texture.get_width()
	var scale_next = canvas_size.x / next_page.texture.get_width()
	
	tw_prep.tween_property(current_page, "scale", Vector2(scale_curr, scale_curr), duration)
	tw_prep.tween_property(next_page, "scale", Vector2(scale_next, scale_next), duration)
	
	# Move pivot to (0, 0), so that positioning by X=0 will push the page to the left edge
	tw_prep.tween_property(current_page, "pivot_offset", Vector2.ZERO, duration)
	tw_prep.tween_property(next_page, "pivot_offset", Vector2.ZERO, duration)

	# Align the current page to the bottom edge of the screen
	var final_h_curr = current_page.texture.get_height() * scale_curr
	tw_prep.tween_property(current_page, "position", Vector2(0, canvas_size.y - final_h_curr), duration)
	
	# Place the next page right below the screen, so that it can slide up during the movement phase
	next_page.position = Vector2(0, canvas_size.y)

	await tw_prep.finished 

	var tw_move = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	
	# Move current page up, so that it goes out of the screen
	tw_move.tween_property(current_page, "position", Vector2(0, -final_h_curr), duration)
	
	# Move the new page from below the screen to the origin (0,0)
	tw_move.tween_property(next_page, "position", Vector2.ZERO, duration)
	
	tw_move.chain().tween_callback(_on_transition_finished)


func _on_transition_finished():
	var old_page = current_page
	pages_buffer.pop_front()
	current_page = pages_buffer[0]
	current_frame_idx = -1

	old_page.queue_free()
	
	owner.manga_tcp_client.get_manga_page(current_page_num + 1)
	
	is_transitioning = false


func build_manga_page(image_bytes: PackedByteArray, meta: Dictionary) -> void:
	Debugger.info("Creating new page...")
	var image := Image.new()
	var error = image.load_jpg_from_buffer(image_bytes)

	if error != OK:
		Debugger.error("Error loading JPEG: " + str(error))
		return

	var texture = ImageTexture.create_from_image(image)
	var page_node = page_scene.instantiate()
	add_child(page_node)

	page_node.set_page(texture, meta)
	pages_buffer.append(page_node)
	
	if current_page == null:
		current_page = page_node
		current_page.visible = true
		# pivot at center
		current_page.pivot_offset = current_page.size / 2
		# Screen center
		current_page.position = (canvas_size / 2) - current_page.pivot_offset
		current_frame_idx = -1
		
		owner.manga_tcp_client.get_manga_page(current_page_num + 1)
	else:
		page_node.visible = false
		page_node.position = Vector2(canvas_size.x / 2, canvas_size.y * 1.5)

	print("Page ", meta.get("page_num"), " successfully built! Size: ", image_bytes.size())


func clear_buffer(new_page: int) -> void:
	Debugger.info("Clearing page buffer for new page request: " + str(new_page))
	for page in pages_buffer:
		page.queue_free()
	pages_buffer.clear()
	current_page = null
	current_page_num = new_page
	current_frame_idx = -1
