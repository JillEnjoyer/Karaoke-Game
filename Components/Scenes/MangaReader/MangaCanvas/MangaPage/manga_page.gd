## This thing is a picture with masks on top, which will be revealed one by one. It also stores metadata about frames for later use. ##
extends TextureRect

var masks: Dictionary = {}
var meta: Dictionary = {}


func set_page(page_texture: ImageTexture, data: Dictionary) -> void:
	self.texture = page_texture
	self.meta = data
	self.size = page_texture.get_size()
	self.modulate.a = 1.0

	self.pivot_offset = Vector2.ZERO
	create_frame_masks(data)


func create_frame_masks(data: Dictionary) -> void:
	var frames_data = data.get("frames", [])
	for i in range(frames_data.size()):
		var f = frames_data[i]

		var mask = ColorRect.new()
		mask.color = Color.WHITE_SMOKE

		mask.position = Vector2(f.get("x", 0), f.get("y", 0))
		mask.size = Vector2(f.get("w", 0), f.get("h", 0))

		mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mask)
		masks[i] = mask


func reveal_frame(idx: int, duration: float):
	if masks.has(idx):
		var tw = create_tween()
		tw.tween_property(masks[idx], "modulate:a", 0.0, duration)


func get_frame_center(idx: int) -> Vector2:
	var f = meta.frames[idx]
	return Vector2(f["center"][0], f["center"][1])


func get_frame_size(idx: int) -> Vector2:
	var f = meta.frames[idx]
	return Vector2(f["w"], f["h"])
