extends Control

var draw_color: Color = Color(1, 0, 0, 0.3) # Прозрачный красный
var is_erasing: bool = false
var image: Image
var texture: ImageTexture

const BRUSH_SIZE = 16

func _ready():
	image = Image.create(get_viewport().size.x, get_viewport().size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # Прозрачность по умолчанию
	texture = ImageTexture.create_from_image(image)
	$TextureRect.texture = texture

func _input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var pos = event.position
		for y in range(BRUSH_SIZE):
			for x in range(BRUSH_SIZE):
				var px = int(pos.x) + x - BRUSH_SIZE / 2
				var py = int(pos.y) + y - BRUSH_SIZE / 2
				var size = image.get_size()
				if px >= 0 and py >= 0 and px < size.x and py < size.y:
					if is_erasing:
						image.set_pixel(px, py, Color(0, 0, 0, 0))
					else:
						image.set_pixel(px, py, draw_color)
		texture.update(image)


func _on_ColorPicker_color_changed(color):
	draw_color = color

func _on_Button_pressed():
	is_erasing = !is_erasing


func export_as_svg():
	var data = []
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.01:
				data.append("1")
			else:
				data.append("0")

	# тут вставить в SVG формат, либо просто сохранить в сжатом бинарном файле


var svg_cache := {}

func get_mask_from_svg(id: String) -> Image:
	if svg_cache.has(id):
		return svg_cache[id]
	var image := convert_svg_to_bitmap(id) # твоя реализация
	svg_cache[id] = image
	return image


func convert_svg_to_bitmap(id: String) -> Image:
	# Заглушка – возвращает пустую маску на 64x64, заменишь на настоящий парсер SVG
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # пустая прозрачная картинка
	return img
