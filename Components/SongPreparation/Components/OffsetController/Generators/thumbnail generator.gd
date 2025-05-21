extends Control
class_name ThumbnailGenerator

var video = Video.new()

func generate_thumbnails(path: String, container_width: int, container_height: int) -> Dictionary:
	var metadata = get_metadata(path)
	var duration: float = metadata.get("duration", 0.0)
	var fps: float = metadata.get("fps", 1.0)
	if duration <= 0:
		Debugger.error("Invalid video duration!")
		return {}

	var thumb_height = container_height
	var thumb_width = thumb_height * 16.0 / 9.0
	var thumb_count: int = max(1, floor(container_width / thumb_width))
	var time_step = duration / thumb_count
	
	Debugger.debug(
		"\nduration: " + str(duration) + "\nfps: " + str(fps) + 
		"\nthumb_height: " + str(thumb_height) + "\nthumb_width: " + str(thumb_width) +
		"\nthumb_count: " + str(thumb_count) + "\ntime_step: " + str(time_step) +
		"\ncontainer_width: " + str(container_width) + "\ncontainer_height: " + str(container_height)
	)
	
	video.open(path)
	var thumbnails: Array = []

	for i in thumb_count:
		var timestamp = i * time_step * fps
		var frame: Image = video.seek_frame(timestamp)
		if frame:
			frame.resize(thumb_width, thumb_height)
			var texture := ImageTexture.create_from_image(frame)
			thumbnails.append(texture)
		else:
			Debugger.warning("Frame missing at time: " + str(timestamp))

	return {
		"metadata": metadata,
		"thumbnails": thumbnails
	}


func get_metadata(path: String) -> Dictionary:
	return video.get_file_meta(path)
	
