extends Control

@onready var video_texture = $TextureRect
@onready var video = Video.new()

signal video_ended

var is_playing = false

var metadata_array = {}
var framerate = 1.0
var length = 1.0 # real file length in seconds
var timer = 1.0 # time between frames in video file (not every get_frame may return it)
var time_passed = 0.0 # time passed between 0 and timer
var speed = 1.0

var playback_position = 0 #in seconds - absolute global time (not affected by offsets)

var video_offset_start = 0 # +time from start of video
var video_offset_end = 0 # -time from end of video
var desired_offset_start = 0
var desired_offset_end = 0

func _ready() -> void:
	pass


func init(video_list):
	var video_path = ""
	for video in video_list:
		video_path = video_list[video]["path"]
		video_offset_start = video_list[video]["params"]["offset_start"]
		video_offset_end = video_list[video]["params"]["offset_end"]
	load_video(video_path)


func load_video(absolute_video_path) -> void:
	#var absolute_video_path = franchise_name + "/" + song_name + "/" + video_link
	Debugger.info("video_renderer.gd", "load_video()", "Trying to load video from: " + absolute_video_path)
	
	if FileAccess.file_exists(absolute_video_path):
		get_video_metadata(absolute_video_path)
		
		var result = video.open(absolute_video_path)
		print(result)
		if result == OK:
			Debugger.debug("video_renderer.gd", "load_video()", "Video opened successfully!")
		else:
			Debugger.error("video_renderer.gd", "load_video()", "Error with video opening: " + result)
	else:
		Debugger.error("video_renderer.gd", "load_video()", "Video file not found: " + absolute_video_path)


func get_video_metadata(absolute_video_path):
	Debugger.debug("video_renderer.gd", "load_video()", "metadata array: \n" + str(metadata_array))
	metadata_array = video.get_file_meta(absolute_video_path)
	length = float(metadata_array.duration)
	framerate = float(metadata_array.fps)
	timer = 1.0/framerate


func update_offsets(offset_start, offset_end):
	desired_offset_start = offset_start
	desired_offset_end = offset_end


func state_update():
	is_playing = false

	video_offset_start = desired_offset_start
	video_offset_end = desired_offset_end
	
	if playback_position < video_offset_start:
		seek(video_offset_start)
		is_playing = true
	if playback_position > (length - video_offset_end):
		seek(video_offset_end)
		emit_signal("video_ended")


func _process(delta: float) -> void:
	if is_playing:
		time_passed += delta * speed
		playback_position += delta * speed
		if time_passed >= timer:
			time_passed -= timer
			update_frame()


func update_frame() -> void:
	video_texture.texture.set_image(video.next_frame())
	#if playback_position > (video_length-video_offset_end -- can be pre calc) then we stop playback


func seek(new_time: float):
	var frame_number = new_time * framerate
	video.seek_frame(frame_number)
	Debugger.info("video_renderer.gd", "seek_video()", "seeked time:" + str(frame_number))


func stop():
	is_playing = false
func start():
	is_playing = true
