extends Control

@onready var blur_texture = $BlurTexture
@onready var texture = $TextureRect
@onready var text = $TextLayer

var mode = "text"


func _ready() -> void:
	pass

func init_text_mode(imported_mode):
	if imported_mode == "image":
		mode = "image"
	else:
		mode = "text"


func import_data(data):
	if mode == "text":
		text = data
	elif mode == "image":
		texture = data
