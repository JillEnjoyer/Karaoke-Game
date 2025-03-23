extends Control

@onready var video_texture = $TextureRect
@onready var video = Video.new()
#
var is_playing = false
var metadata_array = {}
var framerate = 1.0
var length = 1.0
var timer = 1.0

var playback_position = 0 #in seconds - absolute global time (not affected by offsets)
var video_offset_start = 0
var video_offset_end = 0

var desired_offset_start = 0
var desired_offset_end = 0

var video_framerate = 30
var video_speed = 1.0
var video_length = 1.0


func _ready() -> void:
	pass


func get_video_metadata():
	pass


func load_video(absolute_video_path) -> void: # only if during edit/album was choosen other video
	#var absolute_video_path = franchise_name + "/" + song_name + "/" + video_link
	Debugger.info("PlayerSceneControl.gd", "load_video()", "Trying to load video from: " + absolute_video_path)
	
	if FileAccess.file_exists(absolute_video_path):
		metadata_array = video.get_file_meta(absolute_video_path)
		Debugger.debug("PlayerSceneControl.gd", "load_video()", "metadata array: \n" + str(metadata_array))
		
		length = float(metadata_array.duration)
		framerate = float(metadata_array.fps)
		timer = timer/framerate
		
		var result = video.open(absolute_video_path)
		print(result)
		if result == OK:
			Debugger.debug("PlayerSceneControl.gd", "load_video()", "Video opened successfully!")
		else:
			Debugger.error("PlayerSceneControl.gd", "load_video()", "Error with video opening: " + result)
	else:
		Debugger.error("PlayerSceneControl.gd", "load_video()", "Video file not found: " + absolute_video_path)


func update_offsets(offset_start, offset_end):
	desired_offset_start = offset_start
	desired_offset_end = offset_end


func state_update():
	video.state = false #paused

	video_offset_start = desired_offset_start
	video_offset_end = desired_offset_end
	
	video.seek(video_offset_start)
	#also some changes in time


func update_frame() -> void:
	video_texture.texture.set_image(video.next_frame())
	#if playback_position > (video_length-video_offset_end -- can be pre calc) then we stop playback


func seek_video(playtime: float, delta: float):
	var ss = delta * framerate
	video.seek_frame(ss)
	Debugger.info("PlayerSceneControl.gd", "resume_all()", "seeked time:" + str(ss))
	#audio_node.seek(seconds)
	return playtime + delta
