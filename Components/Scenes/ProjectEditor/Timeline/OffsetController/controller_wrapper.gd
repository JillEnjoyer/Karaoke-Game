# controller_wrapper.gd
extends Control
class_name ControllerWrapper

var thumbnail_generator = ThumbnailGenerator.new()
#var waveform_generator = WaveformGenerator.new()
#var context_menu_manager = ContextMenuManager.new()
var value_converter = ValueConverter.new()

var ffmpeg_path = PreferencesData.get_ext_path("ffmpeg")

var node_name := ""
var initial_path := ""
var node_type := ""
var total_duration := 0.0
var px_to_sec_ratio: float = 1.0

var cached_textures: Array = []

@onready var offset_controller_scene = UIManager.get_desired_node("OffsetController")

var selection_manager: SelectionManager
var time_pointer: Control
var context_menu_manager: ContextMenuManager


## ACAPELLA ONLY ##
var subtitles: Array = []
var characters: Array = []
##				##



func import_managers(sm: SelectionManager, tp: Control, cm: ContextMenuManager) -> void:
	selection_manager = sm
	time_pointer = tp
	context_menu_manager = cm


func _ready() -> void:
	SignalBus.context_menu_command_triggered.connect(_on_global_menu_command)

	# Перерисовка шкалы времени при динамическом изменении размера трека
	item_rect_changed.connect(queue_redraw)


func import_initial_data(type_str: String, path: String) -> bool:
	node_type = type_str
	initial_path = path
	
	match node_type:
		"video":
			_setup_thumbnails(path, true)
		"image":
			_setup_thumbnails(path, false)
		"instrumental", "acapella", "bass", "instruments", "drums":
			_setup_waveform(path)
		_:
			Debugger.error("Unknown node type for import_initial_data: %s" % node_type)
			return false

	# Раздаем сгенерированный кэш картинок всем сегментам на треке
	#for seg in get_segments():
	#	seg.apply_visual_data(cached_textures, total_duration)
	
	handle_conflicts()
	return true # <-- Добавь возврат true в самом конце функции


# Внутренний метод генерации миниатюр для видео/картинок
func _setup_thumbnails(path: String, is_video: bool = true) -> bool:
	if not is_video:
		var texture: Texture2D = TextureLoader.load_texture_or_placeholder(path)
		total_duration = 240.0
		cached_textures.clear()
		for i in range(int(240.0 / 5.0)):
			cached_textures.append(texture)
		return true

	# Генерируем пачку картинок (например, 5 штук или на основе таймстампов)
	var data = thumbnail_generator.generate_thumbnails(path, 5)
	cached_textures = data.get("thumbnails", [])
	total_duration = data["metadata"].get("duration", 0.0)
	return true

# Внутренний метод генерации спектрограммы для аудио-треков
func _setup_waveform(path: String) -> void:
	# Фиксируем базовые размеры дорожки под аудио, как в твоем старом коде
	#custom_minimum_size = Vector2(2100.0, 70.0)
	#size = custom_minimum_size
	
	# Подгружаем сплошную текстуру волны через FFmpeg
	var result = WaveformGenerator.load_waveform_image(path, ffmpeg_path, "black")
	custom_minimum_size = Vector2(result.get("size_x", 2100.0), 100.0)
	size = custom_minimum_size
	cached_textures = [result.get("texture", ImageTexture)]
	
	# Если генератор аудио возвращает метаданные с длительностью, можно вытащить её здесь.
	# Если нет, длительность должна передаваться в add_channel или браться из внешнего конфига.



func _on_global_menu_command(command_id: int, target_node: Control) -> void:
	# Самая важная проверка: этот клип лежит на МНЕ (я его родитель)?
	if target_node.get_parent() != self:
		return # Если нет, просто игнорируем! Логику выполнит тот враппер, чей это клип.

	# Если клип наш, выполняем команду
	match command_id:
		0: # Разрезать
			var cut_px = time_pointer.get_absolute_pointer_px() if time_pointer else 0.0
			split_segment(target_node, cut_px)
		1: # Дублировать
			duplicate_segment(target_node)
		2: # Удалить
			delete_segment(target_node)

"""
func init_visuals() -> void:
	if node_type in ["video", "image"]:
		var data = thumbnail_generator.generate_thumbnails(initial_path, 5)
		cached_textures = data.get("thumbnails", [])
		total_duration = data["metadata"].get("duration", 0.0)
	elif node_type in ["instrumental", "acapella"]:
		var tex = waveform_generator.load_waveform_image(initial_path, ffmpeg_path, 2100.0, 70.0, "black")
		cached_textures = [tex]
	
	for seg in get_segments():
		seg.apply_visual_data(cached_textures, total_duration)
	
	handle_conflicts()
"""

# Безопасное динамическое получение сегментов вместо статичного хранения в массиве
func get_segments() -> Array:
	var arr = []
	for child in get_children():
		if child is OffsetController and not child.is_queued_for_deletion():
			arr.append(child)
	return arr


func spawn_segment(id: String, t_start: float, s_start: float, dur: float, total_dur: float) -> OffsetController:
	var seg = offset_controller_scene.instantiate() as OffsetController
	add_child(seg)
	seg.import_managers(selection_manager, time_pointer, context_menu_manager)
	
	seg.setup_segment(id, node_type, t_start, s_start, dur, total_dur, px_to_sec_ratio)
	
	# ИСПРАВЛЕНО: передаем cached_textures вместо пустого массива []
	seg.apply_visual_data(cached_textures, total_dur)
	
	seg.update_visual_position()
	handle_conflicts()
	return seg


# controller_wrapper.gd
func split_segment(node: OffsetController, absolute_cut_px: float) -> void:
	Debugger.info("Продвинутый исправленный Segment split запущен")
	
	# 1. Считаем позицию разреза в секундах относительно таймлайна
	var cut_time = absolute_cut_px / px_to_sec_ratio
	
	# Проверяем, попадает ли разрез внутрь нашего блока
	if cut_time <= node.timeline_start + 0.1 or cut_time >= node.timeline_start + node.duration - 0.1:
		Debugger.warning("Разрез слишком близко к краям клипа, отмена.")
		return

	# Сохраняем исходные данные оригинального блока (до изменений)
	var orig_timeline_start = node.timeline_start
	var orig_source_start = node.source_start
	var orig_duration = node.duration

	# --- ПЕРВЫЙ БЛОК (Левый кусок) ---
	# Его новый duration — это расстояние от его старта до точки реза
	var first_block_new_duration = cut_time - orig_timeline_start
	
	node.duration = first_block_new_duration
	node.update_visual_position() # Корректируем правую границу первого блока


	# --- ВТОРОЙ БЛОК (Правый кусок) ---
	# Вычисляем, на сколько секунд вправо сместилась левая граница нового блока
	var left_handle_delta = cut_time - orig_timeline_start
	
	# Сразу рассчитываем чистые финальные параметры для правой части:
	var new_timeline_start = orig_timeline_start + left_handle_delta  # Стартует точно с места разреза
	var new_source_start = orig_source_start + left_handle_delta      # Превью сдвигается на дельту
	var new_duration = orig_duration - left_handle_delta              # Длина — оставшийся хвостик

	# Спавним второй блок, передавая ему ИСПРАВЛЕННЫЕ параметры СРАЗУ!
	var second_node = spawn_segment(
		node.source_id, 
		new_timeline_start, 
		new_source_start, 
		new_duration, 
		total_duration
	)

	# Пересчитываем сетку трека и слои
	handle_conflicts()



# controller_wrapper.gd
func split_segment_v2(node: OffsetController, absolute_cut_px: float) -> void:
	Debugger.info("Продвинутый Segment split запущен")
	
	# 1. Считаем позицию разреза в секундах относительно начала таймлайна
	var cut_time = absolute_cut_px / px_to_sec_ratio
	
	# Проверяем, попадает ли разрез вообще внутрь нашего блока
	if cut_time <= node.timeline_start + 0.1 or cut_time >= node.timeline_start + node.duration - 0.1:
		Debugger.warning("Разрез слишком близко к краям клипа, отмена.")
		return

	# Сохраняем исходные данные оригинального блока (до изменений)
	var orig_timeline_start = node.timeline_start
	var orig_source_start = node.source_start
	var orig_duration = node.duration

	# 2. Модифицируем ПЕРВЫЙ (оригинальный) блок -> сжимаем его ПРАВУЮ ручку
	# Новый duration для первого блока — это расстояние от его старта до курсора
	var first_block_new_duration = cut_time - orig_timeline_start
	
	node.duration = first_block_new_duration
	node.update_visual_position() # Обновляем визуал (маска пересчитается сама!)

	# 3. Спавним ВТОРОЙ блок (точную копию того, каким был первый)
	var second_node = spawn_segment(
		node.source_id, 
		orig_timeline_start, 
		orig_source_start, 
		orig_duration, 
		total_duration
	)
	
	# 4. Модифицируем ВТОРУЙ блок -> сжимаем его ЛЕВУЮ ручку
	# Нам нужно сымитировать, что левую ручку протащили вправо до cut_time.
	# Вычисляем дельту в секундах, на которую сдвинулась левая граница:
	var left_handle_delta = cut_time - orig_timeline_start
	
	# Применяем формулу "левой ручки" из твоего _apply_drag():
	second_node.timeline_start = orig_timeline_start + left_handle_delta
	second_node.source_start = orig_source_start + left_handle_delta
	second_node.duration = orig_duration - left_handle_delta
	
	second_node.update_visual_position() # Маска идеального сдвига посчитается сама!

	# Пересчитываем слои и сетку трека
	handle_conflicts()


# Упрощенный split_segment, использующий общую функцию спавна
func split_segment_v1(node: OffsetController, absolute_cut_px: float) -> void:
	Debugger.info("Segment split requested")
	
	# ТЕПЕРЬ ВСЁ В ОДНОЙ СИСТЕМЕ КООРДИНАТ ТАЙМЛАЙНА
	var local_x = absolute_cut_px - node.position.x
	
	var time_delta = local_x / px_to_sec_ratio
	if time_delta <= 0.1 or time_delta >= node.duration - 0.1:
		Debugger.warning("Слишком близко к краю клипа, отмена. Delta: " + str(time_delta))
		return
		
	var new_timeline_start = node.timeline_start + time_delta
	var new_source_start = node.source_start + time_delta
	var new_duration = node.duration - time_delta
	
	node.duration = time_delta
	node.update_visual_position()
	
	var _new_seg = spawn_segment(node.source_id, new_timeline_start, new_source_start, new_duration, total_duration)
	handle_conflicts()


func duplicate_segment(node: OffsetController) -> void:
	Debugger.info("Segment duplicate requested")
	var new_timeline_start = node.timeline_start + node.duration
	var _new_seg = spawn_segment(node.source_id, new_timeline_start, node.source_start, node.duration, total_duration)
	handle_conflicts()

func delete_segment(node: OffsetController) -> void:
	Debugger.info("Segment delete requested")
	node.queue_free()
	await get_tree().process_frame
	handle_conflicts()

func handle_conflicts() -> void:
	var segs = get_segments()
	if segs.is_empty():
		_update_wrapper_size()
		return
		
	# Сортируем все элементы трека слева направо
	segs.sort_custom(func(a, b): return a.timeline_start < b.timeline_start)
	
	# ConflictHandler: Если самый левый элемент в минусе, вычисляем разницу и сдвигаем ВСЁ вправо!
	var first_seg = segs[0]
	if first_seg.timeline_start < 0.0:
		var shift = -first_seg.timeline_start
		for seg in segs:
			seg.timeline_start += shift
			seg.update_visual_position()
			seg.position_changed.emit()
			
	_update_wrapper_size()

func _update_wrapper_size() -> void:
	var max_w = 0.0
	for seg in get_segments():
		max_w = max(max_w, seg.position.x + seg.size.x)
	custom_minimum_size.x = max(max_w + 500.0, 1000.0)
	size.x = custom_minimum_size.x
	queue_redraw()

func prepare_export_timecodes() -> Array:
	var data = []
	var segs = get_segments()
	segs.sort_custom(func(a, b): return a.timeline_start < b.timeline_start)
	for seg in segs:
		data.append({
			"id": seg.source_id,
			"start": seg.source_start,
			"end": seg.source_start + seg.duration,
			"timeline_at": seg.timeline_start
		})
	return data

# Возвращенная отрисовка шкалы времени
func _draw() -> void:
	if px_to_sec_ratio <= 0:
		return
		
	var width = size.x
	var height = size.y
	
	# Горизонтальная линия основания
	draw_line(Vector2(0, height - 1), Vector2(width, height - 1), Color(0.4, 0.4, 0.4, 0.4), 1.0)
	
	# Настройка шага шкалы в зависимости от масштаба
	var step_sec = 5.0
	if px_to_sec_ratio < 2.0:
		step_sec = 10.0
	if px_to_sec_ratio < 0.5:
		step_sec = 30.0
	if px_to_sec_ratio < 0.1:
		step_sec = 60.0
		
	var font = get_theme_default_font()
	var font_size = 10
	
	var current_t = 0.0
	while current_t * px_to_sec_ratio < width:
		var x = current_t * px_to_sec_ratio
		var is_major = fmod(current_t, step_sec * 5.0) == 0.0 or current_t == 0.0
		
		var tick_height = 8.0 if is_major else 4.0
		var tick_color = Color(0.6, 0.6, 0.6, 0.5) if is_major else Color(0.4, 0.4, 0.4, 0.2)
		
		draw_line(Vector2(x, height - tick_height), Vector2(x, height), tick_color, 1.0)
		
		if is_major and x + 40 < width:
			var minutes = int(current_t) / 60
			var seconds = int(current_t) % 60
			var time_str = "%02d:%02d" % [minutes, seconds]
			draw_string(font, Vector2(x + 4, height - 4), time_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 0.7, 0.4))
			
		current_t += step_sec

# Прием Drag-and-Drop данных при переносе контроллера с других треков
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "offset_controller"


# Перенос клипа с другого трека (Drag-and-Drop) теперь тоже стал лаконичным
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target_node = data.get("node") as OffsetController
	if is_instance_valid(target_node):
		var old_wrapper = target_node.get_parent()
		if old_wrapper != self:
			# Пересчитываем время старта клипа на новом треке на основе позиции отпускания мыши
			var dropped_timeline_start = at_position.x / px_to_sec_ratio
			
			# Вместо сложного ручного перемещения ноды и переподключения сигналов, 
			# мы просто спавним клон на текущем треке с новыми координатами
			spawn_segment(
				target_node.source_id,
				dropped_timeline_start,
				target_node.source_start,
				target_node.duration,
				target_node.total_duration
			)
			
			# Удаляем старый сегмент с предыдущего трека
			if old_wrapper and old_wrapper.has_method("delete_segment"):
				old_wrapper.delete_segment(target_node)
			else:
				target_node.queue_free()


func receive_generated_subtitles(vosk_subtitles: Array = [], vosk_characters: Array = []) -> void:
	subtitles = vosk_subtitles
	characters = vosk_characters



# Собираем данные трека для финального JSON конфига
func export() -> Dictionary:
	var segments_data: Array = []
	
	for child in get_segments():
		var start_t = snappy_round(child.timeline_start)
		var end_t = null
		
		# ПРОВЕРКА "ДО КОНЦА": Если сумма старта исходника и длительности
		# меньше полной длины файла (с погрешностью 0.1с), значит файл обрезали!
		if child.source_start + child.duration < child.file_total_duration - 0.1:
			end_t = snappy_round(child.timeline_start + child.duration)
			
		segments_data.append({
			"start": start_t,
			"end": end_t
		})
		
	# Сортируем сегменты в хронологическом порядке
	segments_data.sort_custom(func(a, b): return a["start"] < b["start"])
	
	var export_data := {
		"node_name": node_name,
		"node_type": node_type,
		"initial_path": initial_path,
		"segments": segments_data
	}
	
	# Добавляем специфичные ключи в зависимости от типа
	if node_type == "acapella":
		export_data["role"] = node_name
		export_data["subtitles"] = subtitles
		export_data["characters"] = characters
	elif node_type in ["instrumental", "bass", "drums", "instruments"]:
		export_data["instrument"] = node_name
	elif node_type == "video":
		export_data["id"] = node_name
		
	return export_data

# Вспомогательная функция округления до сотых долей (например 15.32)
func snappy_round(value: float) -> float:
	return round(value * 100.0) / 100.0
