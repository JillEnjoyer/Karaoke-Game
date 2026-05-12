extends Control

signal video_ended

@onready var video_texture = $TextureRect

var frame_buffer: FrameBuffer = null
var texture: ImageTexture = null

var speed_multiplier := 1.0 ## used for syncing video (during desync or between online players)
var playing := false


func _ready() -> void:
	pass


func init(song_path: String, video_dict: Dictionary) -> void:
	#wipe_manager()
	Debugger.debug("VIDEO_DICT" + str(video_dict))
	frame_buffer = FrameBuffer.new(song_path, video_dict)
	frame_buffer.connect("video_ended", Callable(self, "video_ended"))


func wipe_manager() -> void:
	if frame_buffer:
		frame_buffer.queue_free()
	frame_buffer = null
	texture = null
	video_texture.texture = null


func update_timer(player_scene_logical_time: float) -> void:
	if playing and frame_buffer and frame_buffer.update_timer(player_scene_logical_time):
		update_frame()


func update_frame() -> void:
	var frame = frame_buffer.get_next_frame()
	if frame:
		if not texture or Vector2i(texture.get_size()) != frame.get_size():
			texture = ImageTexture.create_from_image(frame)
			video_texture.texture = texture
		else:
			video_texture.texture.update(frame)
	else:
		Debugger.warning("No frame received from FrameBuffer. Video is bugged or might be ended")
		emit_signal("video_ended")


func seek(new_logical_time: float):
	frame_buffer.seek(new_logical_time)
	Debugger.info("seeked time:" + str(new_logical_time))


func start(time: float = 0.0) -> void:
	frame_buffer.seek(time)
	playing = true
func resume():
	playing = true
func pause():
	playing = false
