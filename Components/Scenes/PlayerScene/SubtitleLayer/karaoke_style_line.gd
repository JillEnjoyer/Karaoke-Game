extends Control

@export var max_width := 1600
@export var line_height := 100

var character: String = ""
var start_time: float = 0.0
var end_time: float = 0.0
var word_cells := []


func setup(character_name: String, words: Array, line_start: float, line_end: float) -> void:
	character = character_name
	start_time = line_start
	end_time = line_end
	_clear_words()
	_create_words(words)
	_center_line()


func _create_words(words: Array) -> void:
	var current_x := 0
	var current_y := 0
	var space_size := 20
	
	for word_data in words:
		var cell = UIManager.show_ui("word_cell", self)
		cell.set_word(word_data["word"], word_data["style"])
		
		if current_x > 0 and current_x + cell.size.x > max_width:
			current_x = 0
			current_y += line_height
		
		cell.position = Vector2(current_x, current_y)
		
		word_cells.append({
			"cell": cell,
			"position": cell.position,
			"size": cell.size,
			"start": word_data["start"],
			"end": word_data["end"]
		})
		
		current_x += cell.size.x + space_size


func _center_line() -> void:
	if word_cells.is_empty():
		return
	
	var last_cell = word_cells.back()
	var line_width = last_cell["position"].x + last_cell["cell"].size.x
	var offset = (max_width - line_width) / 2
	
	# Сначала центрируем как обычно
	for item in word_cells:
		item["cell"].position.x += offset
		item["position"] = item["cell"].position
	
	# Затем сжимаем, сохраняя центровку
	#_shrink_size()
	#_recenter_after_shrink()


func _shrink_size() -> void:
	if word_cells.is_empty():
		return
	
	# Находим реальную ширину содержимого
	var required_width: float = 0
	for item in word_cells:
		required_width += item["cell"].size.x
		if item != word_cells.back():  # Добавляем пробелы между словами
			required_width += 20  # space_size
	
	# Устанавливаем новую ширину с небольшим отступом
	self.custom_minimum_size.x = required_width + 40
	self.size.x = self.custom_minimum_size.x

func _recenter_after_shrink() -> void:
	if word_cells.is_empty():
		return
	
	# Вычисляем новое смещение для центрирования
	var line_width = word_cells.back()["position"].x + word_cells.back()["cell"].size.x
	var new_offset = (max_width - line_width) / 2
	
	# Применяем новое смещение ко всем словам
	for item in word_cells:
		item["cell"].position.x = item["position"].x - (item["position"].x - item["cell"].position.x) + new_offset
		item["position"] = item["cell"].position


func get_word_positions() -> Array:
	var positions = []
	for word in word_cells:
		positions.append({
			"position": word["position"],
			"size": word["size"],
			"start": word["start"],
			"end": word["end"]
		})
	return positions


func clear() -> void:
	_clear_words()
	start_time = INF
	end_time = INF


func _clear_words() -> void:
	for item in word_cells:
		item["cell"].queue_free()
	word_cells.clear()
