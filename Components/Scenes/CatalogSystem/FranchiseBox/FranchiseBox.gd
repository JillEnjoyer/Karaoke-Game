extends Control

var franchise_name: String
var franchise_path: String

const ICON_SIZE = 220
const BOX_WIDTH = 1675
const BOX_HEIGHT = 250
const TITLE_SIZE = 280
const DESCRIPTION_SIZE = 20
const BACKGROUND_OPACITY = 0.5

var title_font: FontFile

func _ready():
	title_font = FontFile.new()

	#var font_data = load("res://Fonts/Comic Sans MS.ttf") as FontFile
	var font_data = load("res://Fonts/Comic Sans MS.ttf")
	if font_data == null:
		Debugger.error("Font file is not loaded")
	else:
		#title_font.data = font_data
		title_font.fixed_size = TITLE_SIZE
	# Example
	#setup("HazbinHotel", "res://Catalog/")

func setup(f_name: String, f_path: String):
	franchise_name = f_name
	franchise_path = f_path

	custom_minimum_size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	self.add_theme_constant_override("separation", 10)

	# Background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, BACKGROUND_OPACITY)
	background.size = Vector2(BOX_WIDTH, BOX_HEIGHT)
	add_child(background)

	# Icon
	var icon_path = franchise_path + "Icon.png"
	if FileAccess.file_exists(icon_path):
		var icon_texture = load(icon_path)
		var icon = TextureRect.new()
		icon.texture = icon_texture
		icon.set_stretch_mode(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		icon.set_scale(Vector2(ICON_SIZE / icon_texture.get_size().x, ICON_SIZE / icon_texture.get_size().y))  # Scaling icon
		@warning_ignore("integer_division")
		icon.position = Vector2(15, (BOX_HEIGHT - ICON_SIZE) / 2)
		add_child(icon)
	else:
		Debugger.error("Icon.png file is not found at path: " + icon_path)

	# Title
	var title_label = Label.new()
	title_label.text = franchise_name
	title_label.position = Vector2(ICON_SIZE + 40, 20)  # Putting Title at the right from the icon
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#title_label.add_theme_font_override("font", title_font)  # Applying font DynamicFont
	title_label.get_theme_font("font")
	add_child(title_label)

	var description = "Description is missing."
	var description_path = franchise_path + "Data.txt"
	if FileAccess.file_exists(description_path):
		var file = FileAccess.open(description_path, FileAccess.READ)
		if file:
			description = file.get_as_text()
			file.close()

	# Description
	var description_label = Label.new()
	description_label.text = description
	description_label.position = Vector2(ICON_SIZE + 40, 60)  # Putting description below the title
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#description_label.add_theme_font_override("font", title_font)  # Applying font DynamicFont
	description_label.get_theme_font("font")
	add_child(description_label)

	self.connect("gui_input", Callable(self, "_on_franchise_box_pressed"))


func _on_franchise_box_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		Debugger.debug("Chosen franchise: " + franchise_name)
