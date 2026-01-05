extends Control

@onready var texture_rect = $TextureRect

var qrGenerator = ProjectSettings.globalize_path("res://Extensions/qrGenerator.exe")

## Example
## TODO: Remove in production
func _ready():
	var link = "https://example.com1111111"
	var image_texture = generate_qr_code(link)
	
	if image_texture:
		texture_rect.texture = image_texture


func generate_qr_code(link: String) -> ImageTexture:
	var output = []

	var arguments = [link]
	var exit_code = OS.execute(qrGenerator, arguments, output)
	if exit_code != OK:
		Debugger.error("Error with launching qrGenerator.py")
		return null
	
	var width = 0
	var height = 0
	var pixel_data = ""

	#var reading_pixels = false
	for line in output:
		line = line.strip_edges()

		var separator_index = line.find(";")
		if separator_index != -1:
			var size_data = line.substr(0, separator_index).split(",")
			width = int(size_data[0])
			height = int(size_data[1])
			
			# Pixels start after the first ";"
			pixel_data = line.substr(separator_index + 1)
			break

	#var base = Image.new()
	var image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	var x = 0
	var y = 0
	var index = 0
	var data_length = pixel_data.length()
	while index < data_length:
		var current_char = pixel_data[index]
		if current_char == ",":
			# If it is a comma, move on X axis
			x += 1
		elif current_char == ";":
			# if it is a semicolon, move on Y axis
			y += 1
			x = 0
		else:
			# Pixel will be either black or white
			var color = Color.WHITE
			if current_char == "1":
				color = Color.BLACK
			image.set_pixel(x, y, color)

		index += 1
	
	var texture = ImageTexture.create_from_image(image)
	if texture:
		Debugger.debug("Texture created with size: " + str(texture.get_width()) + "x" + str(texture.get_height()))
	else:
		Debugger.error("Error during texture creation.")

	return texture
