extends Control

const SEC_TO_PIXEL_MULTIPLIER = 15

@onready var length_in_sec: float
@onready var length_in_pixels: float

@onready var offset_total: float
@onready var offset_start: float
@onready var offset_end: float

@onready var video_thumbnail_dict: Dictionary = {} #89x50
@onready var audio_spectre_image: Image

func _ready() -> void:
	pass

func init(type: String, total_offset: float, start_offset: float, end_offset: float) -> void:
	offset_total = total_offset
	offset_start = start_offset
	offset_end = end_offset
	
	length_convert()
	
	if type == "Video":
		get_video_thumbnails()
	elif type == "Audio":
		get_audio_spectre()

func length_convert() -> void:
	length_in_pixels = length_in_sec * SEC_TO_PIXEL_MULTIPLIER

func get_video_thumbnails() -> void:
	var video_handler = Video.new()
	var pic_count = length_in_pixels / 89
	var time_step = length_in_sec / pic_count
	var current_timecode = 0.0

	for i in range(pic_count):
		var img: Image = video_handler.get_video_image(current_timecode)
		if img:
			img.resize(89, 50)
			video_thumbnail_dict[i * 89] = img
		current_timecode += time_step

func get_audio_spectre() -> void:
	var process = "spectre_generator.exe"
	var audio_file = "input_audio.wav"
	var output_image = "output_spectre.png"
	OS.execute(process, [audio_file, output_image])
	
	var img = Image.new()
	if img.load(output_image) == OK:
		img.resize(length_in_pixels, 50)
		audio_spectre_image = img

func setup_subtitle_rectangles(subtitles: Array, character_amount: int) -> void:
	for child in get_children():
		child.queue_free()
	
	var rect_height = ((50 / 1.5) / character_amount) - (5 * (character_amount - 1))
	var y_offset = 0

	for subtitle in subtitles:
		var rect = ColorRect.new()
		rect.color = Color(1, 1, 1, 0.5)
		rect.position.x = subtitle.start_time * SEC_TO_PIXEL_MULTIPLIER
		rect.position.y = y_offset
		rect.size.x = (subtitle.end_time - subtitle.start_time) * SEC_TO_PIXEL_MULTIPLIER
		rect.size.y = rect_height
		add_child(rect)
		y_offset += rect_height + 5
