extends Node
class_name VideoController
## Stores video controlling class. Provides data directly to FrameBuffer.

var video = Video.new()

var manager = null

var type := "video"
var image: Image = null
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
			type = "video"
		else:
			Debugger.error("Error with video opening: " + result)
	else:
		Debugger.error("Video file not found: " + video_path)


func get_video_metadata(video_path: String):
	var metadata = Video.get_file_meta(video_path)
	length = float(metadata.duration)
	framerate = float(metadata.fps)
	frametime = 1.0/framerate

	Debugger.debug("Video metadata - Length: " + str(length) + "s, Framerate: " + str(framerate) + "fps, Frametime: " + str(frametime) + "s")


func load_as_image(path) -> void:
	Debugger.info("Loading static image from: " + path)
	if FileAccess.file_exists(path):
		var new_image = Image.new()
		var err = new_image.load(path)
		if err == OK:
			image = new_image
			Debugger.debug("Static image loaded successfully!")
			type = "image"
			length = 600.0
			framerate = 1.0
			frametime = 1.0
		else:
			Debugger.error("Error loading static image: " + str(err))
	else:
		Debugger.error("Static image file not found: " + path)


func start(start_time: float) -> void:
	video.seek_frame(int(start_time * framerate))
func seek(to_time_physical: float) -> Image:
	if type == "video":
		return video.seek_frame(int(to_time_physical * framerate))
	elif type == "image":
		return image
	else:
		Debugger.error("Unknown video type: " + type)
		return null
func get_next_frame() -> Image:
	if type == "video":
		return video.next_frame()
	elif type == "image":
		return image
	else:
		Debugger.error("Unknown video type: " + type)
		return null


func _exit_tree() -> void:
	video.close()
