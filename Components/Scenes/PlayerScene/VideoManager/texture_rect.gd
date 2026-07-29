extends TextureRect

@export var animation_duration: float = 1.5
var shader_material: ShaderMaterial

func _ready() -> void:
	shader_material = material as ShaderMaterial
	# Если захочется еще сильнее «растворить» картинку, подними этот параметр в инспекторе до 0.12 - 0.15
	shader_material.set_shader_parameter("water_spread", 0.08)

# Анимация: Акварель затекает к центру
func blur_to_center() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(shader_material, "shader_parameter/progress", 1.0, animation_duration)

# Анимация: Вода высыхает, возвращается четкое видео
func blur_from_center() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(shader_material, "shader_parameter/progress", 0.0, animation_duration)
