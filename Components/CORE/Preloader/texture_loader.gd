extends Node
## TODO: Investigate if its possible to use as a static class than Singleton instance

const TEXTURE_EXTENSIONS := [".png", ".jpg", ".jpeg", ".webp", ".bmp"]

var DEFAULT_ICON := preload("res://GlobalAssets/icon.svg")


func load_texture_or_placeholder(file_path: String) -> Texture2D:
	if file_path.get_extension() == "":
		for ext in TEXTURE_EXTENSIONS:
			Debugger.debug("Trying: " + file_path + ext)
			if FileAccess.file_exists(file_path + ext):
				file_path += ext
				break
			if ext == TEXTURE_EXTENSIONS[TEXTURE_EXTENSIONS.size() - 1]:
				Debugger.error("No texture found for: " + file_path)
				return DEFAULT_ICON

	var texture = load_texture(file_path)
	if texture == null:
		Debugger.error("Used default icon")
		return DEFAULT_ICON
	return texture


func load_texture(file_path: String):
	if FileAccess.file_exists(file_path):
		var img = Image.new()
		if img.load(file_path) == OK:
			return (ImageTexture.create_from_image(img))
	Debugger.error('"' + file_path + '"' + " is not exist")
	return null
