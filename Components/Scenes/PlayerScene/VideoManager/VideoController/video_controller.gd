extends Node
class_name VideoController
## Stores video controlling class. Provides data directly to FrameBuffer.

var video = Video.new()

var manager = null

var length := 1.0
var framerate := 1.0
var frametime := 1.0

func _init(manager_node) -> void:
	manager = manager_node


func load_video(video_path: String) -> void:
	Debugger.info("Trying to load video from: " + video_path)
	if FileAccess.file_exists(video_path):
		get_video_metadata(video_path)
		
		var result = video.open(video_path, false)
		if result == OK:
			Debugger.debug("Video opened successfully!")
		else:
			Debugger.error("Error with video opening: " + result)
	else:
		Debugger.error("Video file not found: " + video_path)


func get_video_metadata(video_path: String):
	var metadata = Video.get_file_meta(video_path)
	length = float(metadata.duration)
	framerate = float(metadata.fps)
	frametime = 1.0/framerate


func start(start_time: float) -> void:
	video.seek_frame(int(start_time * framerate))
func seek(to_time_physical: float) -> Image:
	return video.seek_frame(int(to_time_physical * framerate))
func get_next_frame() -> Image:
	return video.next_frame()


func _exit_tree() -> void:
	video.close()
