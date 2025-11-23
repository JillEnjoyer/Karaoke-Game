extends Control

@onready var blur_texture = $BlurTexture
@onready var texture = $TextureRect
@onready var text = $TextLayer

var mode: String = "text"
var start_time: float = 0.0
var end_time: float = 1.0

var example: Dictionary = {
	"color": "#FFFFFF",
	"font_size": 24,
	"font_type": "Arial",
	"bold": true,
	"italic": false,
	"mask": "maskObject1"
}


func _ready() -> void:
	pass


func set_word(word: String, style: Dictionary) -> void:
	text.text = word
	text.size = text.get_minimum_size()
	text.position = Vector2(
		(size.x - text.size.x) / 2,
		(size.y - text.size.y) / 2
	)
	
	size = text.size + Vector2(10, 10)
	
	if mode == "image":
		set_word_as_texture()
	else:
		text.visible = true
		texture.visible = false


func set_word_as_texture() -> void:
	texture.texture = get_text_texture(text)
	text.visible = false
	texture.visible = true


func init_text_mode(imported_mode):
	if imported_mode == "image":
		mode = "image"
	else:
		mode = "text"

"""
func import_data(data):
	if mode == "text":
		text = data
	elif mode == "image":
		texture = data
"""

func get_text_texture(current_label: Label) -> Texture2D:
	var texture_getter = UIManager.show_ui("texture_getter", self)
	return texture_getter.label_to_texture(current_label)
