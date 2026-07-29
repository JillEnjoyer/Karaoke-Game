extends Control
class_name WordCell

@onready var blur_texture = $BlurTexture
@onready var texture = $TextureRect
@onready var text = $TextLayer

var mode: String = "text"

# Безопасное хранение позиции и твина
var _base_inner_pos: Vector2 = Vector2.ZERO
var _has_base_pos: bool = false
var _bounce_tween: Tween

func _ready() -> void:
	pass

func set_word(word: String, style: Dictionary = {}) -> void:
	text.text = word
	
	# Применяем кастомные стили, если они есть
	if style.has("color"):
		text.add_theme_color_override("font_color", Color(style["color"]))
	if style.has("font_size"):
		text.add_theme_font_size_override("font_size", style["font_size"])
	
	text.size = text.get_minimum_size()
	text.position = Vector2(
		(size.x - text.size.x) / 2,
		(size.y - text.size.y) / 2
	)
	
	size = text.size + Vector2(10, 10)
	
	# ЖЕСТКАЯ ФИКСАЦИЯ БАЗОВОЙ ПОЗИЦИИ (Фикс уплывания)
	# Запоминаем позицию один раз для текста. Для картинки запомним после генерации текстуры.
	_base_inner_pos = text.position
	_has_base_pos = true
	
	if mode == "image":
		set_word_as_texture()
	else:
		text.visible = true
		texture.visible = false

func set_word_as_texture() -> void:
	texture.texture = get_text_texture(text)
	text.visible = false
	texture.visible = true
	
	# Перезаписываем базовую позицию для режима картинки, так как у нее центр такой же
	texture.position = text.position
	_base_inner_pos = texture.position

func init_text_mode(imported_mode: String) -> void:
	if imported_mode == "image":
		mode = "image"
	else:
		mode = "text"

func get_text_texture(current_label: Label) -> Texture2D:
	var texture_getter = UIManager.show_ui("TextureGetter", self)
	if texture_getter.has_method("label_to_texture"):
		return texture_getter.label_to_texture(current_label)
	return null

# Метод для подсветки активного слова и запуска отдачи
func set_highlight(active: bool) -> void:
	var target_node = texture if mode == "image" else text
	
	if active:
		# Окрашиваем в красный цвет
		text.add_theme_color_override("font_color", Color.RED)
		texture.modulate = Color.RED
		
		# Запускаем анимацию толчка
		_play_impact_bounce()
	else:
		# Возвращаем дефолтные цвета
		text.remove_theme_color_override("font_color")
		texture.modulate = Color.WHITE
		
		# Если это слово гасится, принудительно убиваем его твин и возвращаем на базу
		if _bounce_tween:
			_bounce_tween.kill()
		if target_node and _has_base_pos:
			target_node.position = _base_inner_pos

# Безопасная логика микродвижения вниз (отдача при приземлении)
func _play_impact_bounce() -> void:
	var target_node = texture if mode == "image" else text
	if not target_node or not _has_base_pos: return
	
	# СБРОС (Фикс застревания на полпути):
	# Если твин уже работал, убиваем его и МГНОВЕННО возвращаем ноду в чистый ноль
	if _bounce_tween:
		_bounce_tween.kill()
	target_node.position = _base_inner_pos
	
	_bounce_tween = create_tween()
	
	# 1. Резко прожимаем текст вниз на 10 пикселей за 0.05 сек (момент удара)
	_bounce_tween.tween_property(target_node, "position:y", _base_inner_pos.y + 10.0, 0.05)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# 2. Мягко возвращаем обратно в дефолтную позицию за 0.15 сек
	_bounce_tween.tween_property(target_node, "position:y", _base_inner_pos.y, 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)