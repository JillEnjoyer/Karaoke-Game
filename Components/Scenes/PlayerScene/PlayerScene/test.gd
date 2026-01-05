extends Control

@export var blur_amount := 0.0
@export var blur_strength := 0.7
@export var blur_radius := 12.0

@onready var mat := $TextureRect.material as ShaderMaterial

func _ready() -> void:
	mat.set_shader_parameter("blur_amount", blur_amount)
	mat.set_shader_parameter("blur_strength", blur_strength)
	mat.set_shader_parameter("blur_radius", blur_radius)
