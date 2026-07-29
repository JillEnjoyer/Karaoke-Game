extends Control
class_name OffsetController

signal segment_interaction_ended(node)
#signal request_delete(node)
#signal request_split(node, x_pos)
#signal request_copy(node)

@onready var thumb_container := $ThumbnailContainer
@onready var thumbnails_hbox := $ThumbnailContainer/HBoxContainer
@onready var left_handle := $LeftHandle
@onready var right_handle := $RightHandle
var selection_manager: SelectionManager
var time_pointer: Control
var context_menu_manager: ContextMenuManager

# Свойства в секундах 
var source_id: String = ""
var node_type: String = ""
var file_total_duration: float = 0.0
var timeline_start: float = 0.0
var source_start: float = 0.0
var duration: float = 0.0
var px_to_sec_ratio: float = 1.0

# Флаги перетаскивания 
var is_dragging := false
var drag_mode := "" # "move", "left", "right"
var drag_mouse_start_x := 0.0
var initial_timeline_start := 0.0
var initial_source_start := 0.0
var initial_duration := 0.0


func import_managers(sm: SelectionManager, tp: Control, cm: ContextMenuManager) -> void:
	selection_manager = sm
	time_pointer = tp
	context_menu_manager = cm


func _ready() -> void:
	#context_menu_manager = owner.context_menu_manager
	#time_pointer = UIManager.find_scene_in_scene_tree("TimePointer")
	# 2. Обеспечиваем жесткую обрезку текстур по границам клипа при Cut
	clip_contents = true
	
	# Подключаем обработку кликов мыши на сам сегмент
	gui_input.connect(_on_gui_input)
	
	# Подключаем обработку кликов на ручки обрезки
	if left_handle:
		left_handle.gui_input.connect(func(event): _on_handle_input(event, "left"))
	if right_handle:
		right_handle.gui_input.connect(func(event): _on_handle_input(event, "right"))

func setup_segment(id, type, t_start, s_start, dur, total_dur, ratio):
	source_id = id
	node_type = type
	timeline_start = t_start
	source_start = s_start
	duration = dur
	file_total_duration = total_dur
	px_to_sec_ratio = ratio
	update_visual_position()

# 1. Исправление картинок: создаем сущности на основе кэша враппера
func apply_visual_data(textures: Array, total_dur: float) -> void:
	file_total_duration = total_dur
	
	if thumbnails_hbox:
		# Чистим старые TextureRect, если они были
		for child in thumbnails_hbox.get_children():
			child.queue_free()
			
		if node_type in ["video", "image"]:
			var thumb_duration = 5.0 # Интервал нарезки из генератора враппера 
			for tex in textures:
				if tex is Texture2D:
					var tex_rect = TextureRect.new()
					tex_rect.texture = tex
					tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
					tex_rect.custom_minimum_size = Vector2(thumb_duration * px_to_sec_ratio, 70.0)
					thumbnails_hbox.add_child(tex_rect)
					
		elif node_type in ["instrumental", "acapella"]:
			# Для аудио используем одну сплошную текстуру спектрограммы 
			if textures.size() > 0 and textures[0] is Texture2D:
				var tex_rect = TextureRect.new()
				tex_rect.texture = textures[0]
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
				tex_rect.custom_minimum_size = Vector2(file_total_duration * px_to_sec_ratio, 70.0)
				thumbnails_hbox.add_child(tex_rect)
				
	update_visual_position()

func update_visual_position() -> void:
	position.x = timeline_start * px_to_sec_ratio
	size.x = duration * px_to_sec_ratio
	thumb_container.custom_minimum_size.x = size.x
	
	# 2. Исправление Cut: смещаем контейнер влево, чтобы картинка оставалась на месте таймлайна
	if thumb_container:
		thumb_container.position.x = -source_start * px_to_sec_ratio

func _start_drag(mode: String, mouse_x: float) -> void:
	is_dragging = true
	drag_mode = mode
	drag_mouse_start_x = mouse_x
	initial_timeline_start = timeline_start
	initial_source_start = source_start
	initial_duration = duration

func _end_drag() -> void:
	if is_dragging:
		is_dragging = false
		drag_mode = ""
		emit_signal("segment_interaction_ended", self)
		# 4. Провоцируем отрисовку _draw ТОЛЬКО по окончании движения
		queue_redraw()


func _apply_drag(delta: float):
	Debugger.debug("delta: " +  str(delta))
	match drag_mode:
		"move":
			var target = initial_timeline_start + delta
			var timeline = UIManager.find_scene_in_scene_tree("Timeline") 
			if timeline and timeline.has_method("get_snapped_time"):
				timeline_start = timeline.get_snapped_time(target, duration, self) 
			else:
				timeline_start = target
		"left":
			var d = clamp(delta, -initial_source_start, initial_duration - 0.1) 
			timeline_start = initial_timeline_start + d 
			source_start = initial_source_start + d 
			duration = initial_duration - d 
		"right":
			duration = clamp(initial_duration + delta, 0.1, file_total_duration - source_start) 
	update_visual_position()


# 1. Ловим правый клик мыши на самом клипе
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag("move", get_global_mouse_position().x)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu() # <--- МЫ ПОМЕНЯЛИ ЭТУ СТРОЧКУ!

# 2. Ловим клики на ручках (я убрал закомментированный мусор для чистоты)
func _on_handle_input(event: InputEvent, mode: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag(mode, get_global_mouse_position().x)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_context_menu()
			accept_event()

# 3. Глобальный опрос мыши (ОСТАВЛЯЕМ КАК ЕСТЬ, это двигатель перетаскивания)
func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
		
	if event is InputEventMouseMotion:
		var delta_sec = (get_global_mouse_position().x - drag_mouse_start_x) / px_to_sec_ratio 
		_apply_drag(delta_sec) 
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_end_drag()


func _show_context_menu():
	if context_menu_manager:
		context_menu_manager.show_menu(
			get_global_mouse_position(),
			["Split", "Duplicate", "Delete"],
			self # Передаем себя как цель
		)


# 4. Оптимизация рисования: пропускаем рендер во время перетаскивания
func _draw() -> void:
	if is_dragging:
		# Рисуем только легкую полупрозрачную рамку-превью, чтобы интерфейс не лагал
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.4), false, 2.0)
		return
		
	# Твоя оригинальная тяжелая логика отрисовки (выполняется, когда не перетаскиваем):
	# (Пример базовой рамки вокруг готового клипа, можешь вернуть сюда свои старые шейдеры/линии)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.45, 0.8, 0.15), true) # Фон клипа
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.6, 1.0, 0.7), false, 1.5) # Контур
