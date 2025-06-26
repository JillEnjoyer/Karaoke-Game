extends Node

func load_texture_or_placeholder(file_path: String) -> Texture2D:
	var texture = load_texture(file_path)
	if texture == null:
		return preload("res://GlobalAssets/icon.svg")
		Debugger.error("Used default icon")
	return texture


func load_texture(file_path: String):
	if FileAccess.file_exists(file_path):
		var img = Image.new()
		if img.load(file_path) == OK:
			return (ImageTexture.create_from_image(img))
	Debugger.error('"' + file_path + '"' + " is not exist")
	return null
