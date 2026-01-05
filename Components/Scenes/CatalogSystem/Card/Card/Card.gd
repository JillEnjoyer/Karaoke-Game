extends Control

@onready var name_lbl = $NameLbl
@onready var about_lbl = $AboutLbl
@onready var icon_rect = $Thumbnail
@onready var name_rect = $NameRect


func _ready():
	pass


func import_data(song_name: String = "No data", about_str: String = "No data", album_img: Texture = null, name_img: Texture = null):
	name_lbl.text = song_name
	about_lbl.text = about_str

	if album_img != null:
		icon_rect.texture = album_img
	else:
		## TODO: put basic Godot Placeholder
		pass

	if name_img != null:
		name_lbl.visible = false
		name_rect.texture = name_img
	else:
		name_rect.visible = false
		name_lbl.text = song_name
