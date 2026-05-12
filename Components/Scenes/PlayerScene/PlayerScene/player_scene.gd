extends Control
## Scene part:
## Pass playlist to MediaPlayer
## Translate inputs of UI layer to player

@onready var ui = $UI
@onready var media_player = $MediaPlayer


func _ready() -> void:
	pass#ui.connect_media_player(media_player)


func import_playlist(input_data: Dictionary, imported_playlist: Array) -> void:
	media_player.import_playlist(input_data, imported_playlist)


## UI related input funcs
