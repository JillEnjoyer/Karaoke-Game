extends Control

signal pointer_moved(absolute_time_sec)

@onready var drag_btn = $DragBtn
# Ссылка на ScrollContainer, в котором лежат треки. 
# Можно получить через UIManager, либо передать из Timeline.gd при инициализации
@onready var timeline_scroll : Control #UIManager.find_scene_in_scene_tree("TimelinePanel/ScrollContainer")

var is_dragging := false
var scroll_direction := 0
var absolute_time_sec := 0.0

# Настройки автоскролла у краев
const EDGE_MARGIN := 50.0 
const SCROLL_SPEED := 600.0

# Твоя константа конвертации
const PX_TO_SEC_RATIO := (70.0 * 16.0 / 9.0) / 5.0

func import_scroll_container(scroll_container: Control) -> void:
	timeline_scroll = scroll_container

func _ready():
	drag_btn.gui_input.connect(_on_drag_btn_gui_input)
	set_process(false) # Выключаем _process, чтобы не жрал ресурсы, пока не тащим поинтер

func _on_drag_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			set_process(true) # Включаем обработку кадров для автоскролла
		else:
			is_dragging = false
			scroll_direction = 0
			set_process(false)
			
	elif is_dragging and event is InputEventMouseMotion:
		# Получаем позицию мыши относительно родителя (TimeBar'а)
		var local_mouse_x = get_parent().get_local_mouse_position().x
		var half_w = size.x / 2.0
		
		# Сдвигаем лимиты на половину ширины. 
		# Теперь ЦЕНТР поинтера может стоять ровно на 0 и ровно на 100% (get_parent().size.x)
		position.x = clamp(local_mouse_x - half_w, -half_w, get_parent().size.x - half_w)
		
		_update_time_and_label()
		
		# Скролл срабатывает, только если мы тянем мышку физически ЗА пределы таймлайна
		if local_mouse_x < 0:
			scroll_direction = -1
		elif local_mouse_x > get_parent().size.x:
			scroll_direction = 1
		else:
			scroll_direction = 0

func _process(delta: float) -> void:
	# Вызывается каждый кадр ТОЛЬКО если мы зажали мышь (is_dragging = true)
	if scroll_direction != 0:
		var scroll_bar = timeline_scroll.get_h_scroll_bar()
		scroll_bar.value += scroll_direction * SCROLL_SPEED * delta
		# При скролле позиция поинтера визуально стоит на месте, 
		# но "абсолютное" время под ним меняется
		_update_time_and_label()

func _update_time_and_label() -> void:
	absolute_time_sec = get_absolute_pointer_px() / PX_TO_SEC_RATIO
	
	# Выводим время на кнопку (если DragBtn это Button, у нее есть text)
	# Можешь добавить дочернюю Label, если кнопка стилизована иначе: $DragBtn/TimeLabel.text
	if drag_btn is Button:
		drag_btn.text = "%.2f s" % absolute_time_sec
		
	pointer_moved.emit(absolute_time_sec)

# Удобная функция, которую будет вызывать offset_controller при разрезании
func get_absolute_pointer_px() -> float:
	var scroll_offset = timeline_scroll.get_h_scroll_bar().value
	var center_x = position.x + (size.x / 2.0)
	return center_x + scroll_offset
