extends Control

@onready var texture_rect = $TextureRect

## TODO: Need to import it before start
func _ready() -> void:
	texture_rect.texture = load("res://Components/Scenes/PlayerScene/SubtitleLayer/Components/Pentogram_classic.svg")
func import_texture(texture: Texture2D) -> void:
	texture_rect.texture = texture


func jump_to_pos(position: Vector2) -> void:
	## Gets own position, then target position and then calculates trajectory and moves with tween
	pass

func clear():
	texture_rect.texture = null
