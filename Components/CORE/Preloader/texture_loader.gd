extends Node

class_name TextureLoader

func load_texture_or_placeholder(file_path: String) -> Texture2D:
	var texture = load_texture(file_path)
	if texture == null:
		return preload("res://icon.svg")
	return texture


func load_texture(file_path: String):
	if FileAccess.file_exists(file_path):
		var img = Image.new()
		if img.load(file_path) == OK:
			return (ImageTexture.create_from_image(img))
		return null
