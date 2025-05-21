extends Control

signal new_project_closed(value)

@onready var FranchiseTE = $Panel/FranchiseLbl/FranchiseTE
@onready var AlbumVBox = $Panel/AlbumLbl/FolderListVBox/FolderInputsVBox
@onready var SongTE = $Panel/SongLbl/SongTE
@onready var AlbumIcons = $Panel/ScrollContainer/AlbumAddIcons
@onready var folder_inputs_vbox = $Panel/AlbumLbl/FolderListVBox/FolderInputsVBox

var file_struct = FileStructurePreparation.new()
var file_manager = FileManager.new()
var text_loader = TextureLoader.new()

var fm: FileDialog = null
var folder_steps: Array[String] = []
var folder_types: Array[String] = []

const BASE_PRESET: Dictionary = {
	"Name": "",
	"Icon": "",
	"Background": ""
}
var folder_images: Dictionary = {
	"franchise": BASE_PRESET.duplicate(true),
	"album": {},
	"song": BASE_PRESET.duplicate(true)
}
#var image_paths: Dictionary = {}

func _ready() -> void:
	pass


func _on_add_folder_button_pressed() -> void:
	var row = HBoxContainer.new()
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Enter folder name"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var remove_button = Button.new()
	remove_button.text = "-"
	remove_button.focus_mode = Control.FOCUS_NONE
	remove_button.pressed.connect(func():
		row.queue_free()
	)
	row.add_child(line_edit)
	row.add_child(remove_button)
	folder_inputs_vbox.add_child(row)


func _on_bgr_btn_pressed() -> void:
	close_window()
func _on_discard_btn_pressed() -> void:
	close_window()


func _on_accept_btn_pressed() -> void:
	fill_data_vars()
	var path: String = PreferencesData.SettingsList["catalog_path"]
	for i in folder_steps.size():
		var step = folder_steps[i]
		var step_type = folder_types[i]
		path += "/" + step
		file_struct.ensure_folders_exist(path)
		file_struct.copy_default_json(path, step_type)
		match step_type:
			"franchise":
				file_struct.add_chosen_images(path, folder_images["franchise"])
			"album":
				if folder_images["album"].has(str(i)):
					file_struct.add_chosen_images(path, folder_images["album"][str(i)])
			"song":
				file_struct.add_chosen_images(path, folder_images["song"])
	close_window()
	emit_signal("new_project_closed", true)


func fill_data_vars() -> void:
	folder_steps.clear()
	folder_types.clear()

	folder_steps.append(FranchiseTE.text)
	folder_types.append("franchise")

	for child in AlbumVBox.get_children():
		for another_child in child.get_children():
			if another_child is LineEdit:
				var name = another_child.text
				folder_steps.append(name)
				folder_types.append("album")
	folder_steps.append(SongTE.text)
	folder_types.append("song")

	for i in folder_steps.size():
		var step = folder_steps[i]
		var step_type = folder_types[i]
		match step_type:
			"album":
				folder_images["album"][str(i)] = BASE_PRESET.duplicate(true)
			"franchise", "song":
				pass


func close_window() -> void:
	self.queue_free()


func show_fm(file_manager: FileDialog):
	UIManager.new_child(file_manager, self)
	file_manager.popup_centered_ratio(0.8)


func _on_franchise_icon_btn_pressed() -> void:
	show_fm(file_manager.open(_franchise_image_returned, "image"))
func _franchise_image_returned(paths: PackedStringArray) -> void:
	var path = paths[0]
	$Panel/FranchiseIconLbl/FranchiseTextureRect.texture = text_loader.load_texture_or_placeholder(path)
	folder_images["franchise"]["Icon"] = path


func _on_album_icon_btn_pressed() -> void:
	show_fm(file_manager.open(_album_image_returned, "image"))
func _album_image_returned(paths: PackedStringArray) -> void:
	var i = 1
	folder_images["album"].clear()

	for path in paths:
		var tex_rect = TextureRect.new()
		tex_rect.texture = text_loader.load_texture_or_placeholder(path)
		tex_rect.custom_minimum_size = Vector2(200, 150)
		tex_rect.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.StretchMode.STRETCH_SCALE
		AlbumIcons.add_child(tex_rect)

		var album_preset = BASE_PRESET.duplicate(true)
		album_preset["Icon"] = path
		folder_images["album"][str(i)] = album_preset
		i += 1


func _on_song_icon_btn_pressed() -> void:
	show_fm(file_manager.open(_song_image_returned, "image"))
func _song_image_returned(paths: PackedStringArray) -> void:
	var path = paths[0]
	$Panel/SongIconLbl/SongTextureRect.texture = text_loader.load_texture_or_placeholder(path)
	folder_images["song"]["Icon"] = path


func _on_remove_images_button_pressed() -> void:
	for child in AlbumIcons.get_children():
		if child is TextureRect:
			child.queue_free()
