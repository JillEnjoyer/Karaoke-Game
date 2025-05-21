#tutorial.gd
extends Control

@onready var popup = UIManager.show_ui("popup", self)

func _ready() -> void:
	call_deferred("_start_tutorial_async")


func _start_tutorial_async():
	if PreferencesData.UserData["song_preparation_tutorial_passed"] == false:
		var tutorial_data = [
			["New project button lets you choose materials, that would make the appearance of Catalog cards and theirs description", "next", Vector2(0, 70)],
			["Open Existing button lets you choose config file, that would open already prepared song project and its materials with presets", "next", Vector2(188, 70)],
			["Color Picker is supposed to open get a color to setup it to text. Currenly WIP", "next", Vector2(376, 70)],
			["Masking Layer button allows you to work with masks - objects, that would hide parts of the text. Currently WIP", "next", Vector2(440, 70)],
			["Subtitle Layer button allows you to work with words and their positions on the scene (size, position, style etc). Choosen automatically. Not for Karaoke mode! Currently WIP", "next", Vector2(504, 70)],
			["File Manager button lets you choose materials, that you want to use with currently choosen project", "next", Vector2(568, 70)],
			# и т.д.
		]

		for data in tutorial_data:
			popup.position = data[2]
			popup.set_info(data[0], data[1])
			await popup.wait_for_close()
