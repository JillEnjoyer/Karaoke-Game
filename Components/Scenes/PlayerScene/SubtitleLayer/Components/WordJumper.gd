extends Control

@onready var texture_rect = $TextureRect

func _ready() -> void:
	texture_rect.texture = load("res://Components/PlayerScene/SubtitleLayer/Components/Pentogram_classic.svg")

func import_texture(texture: Texture2D) -> void:
	texture_rect.texture = texture
