extends Control

var is_dragging := false
var drag_start_x := 0.0
var initial_offset := 0.0

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Начало перетаскивания
			is_dragging = true
			drag_start_x = event.global_position.x
			initial_offset = get_theme_constant("margin_left")
		else:
			# Конец перетаскивания
			is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		# Вычисляем смещение
		var drag_delta = event.global_position.x - drag_start_x
		var new_offset = initial_offset + drag_delta
		
		# Применяем смещение только к текущей дорожке
		add_theme_constant_override("margin_left", clamp(new_offset, 0, 10000))  # Ограничиваем смещение
		
		# Обновляем позицию содержимого (offset_controller)
		for child in get_children():
			if child is Control:
				child.position.x = new_offset
