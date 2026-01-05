# SongBox.gd
extends VBoxContainer


func setup(song_name: String, song_path: String):
	name = song_name
	add_theme_constant_override("separation", 10)

	# Icon
	var icon_texture = load(song_path + "Icon.png")
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(icon)

	# Title
	var title_label = Label.new()
	title_label.text = song_name
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(title_label)

	# Description
	var description = "Description is missing."
	var file_path = song_path + "Data.txt" ## is it realy has this name?
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			description = file.get_as_text()
			file.close()
		else:
			Debugger.error("Failed to open file for reading: " + file_path)
	else:
		Debugger.error("File Data.txt not found at path: " + file_path)

	var description_label = Label.new()
	description_label.text = description
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(description_label)

	connect("gui_input", Callable(self, "_on_song_box_pressed"))

func _on_song_box_pressed(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		Debugger.debug("Chosen song: ", name)
		get_tree().call_group("root", "load_media", name) ## Don't remember a purpose of that
