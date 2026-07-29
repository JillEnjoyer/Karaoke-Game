extends Control

signal timeline_changed

@onready var name_scroll_container = $HSplitContainer/NamePanel/ScrollContainer
@onready var timeline_scroll_container = $HSplitContainer/TimelinePanel/ScrollContainer

@onready var vbox_names = $HSplitContainer/NamePanel/ScrollContainer/VBoxNames
@onready var vbox_timelines = $HSplitContainer/TimelinePanel/ScrollContainer/VBoxTimelines

@onready var h_scroll = $HSplitContainer/TimelinePanel/TimeBar/HScrollBar
@onready var time_pointer = $HSplitContainer/TimelinePanel/TimePointer

@onready var time_bar_start_time = $HSplitContainer/TimelinePanel/TimePointer
@onready var time_bar_end_time = $HSplitContainer/TimelinePanel/TimePointer

@onready var drop_zone = $DropZone
@onready var selection_manager = $SelectionManager

var context_menu_manager = ContextMenuManager.new()

var TrackHeaderScene = UIManager.get_desired_node("TrackHeader")
var ControllerWrapperScene = UIManager.get_desired_node("ControllerWrapper")

# Коэффициент пикселей на секунду (используется для отрисовки)
var px_to_sec_ratio: float = (70.0 * 16.0 / 9.0) / 5.0 
var _active_idx: int = -1

func _ready() -> void:
	add_child(context_menu_manager)


	time_pointer.import_scroll_container(timeline_scroll_container)
	
	drop_zone.visible = false
	drop_zone.timeline = self
	_sync_scrolling()
	
	if time_pointer:
		time_pointer.pointer_moved.connect(_on_time_pointer_moved)
		#time_pointer.move_timeline.connect(_on_timeline_move_requested)

func _sync_scrolling():
	var v_scroll_names = name_scroll_container.get_v_scroll_bar()
	var v_scroll_time = timeline_scroll_container.get_v_scroll_bar()
	
	v_scroll_names.value_changed.connect(func(val): v_scroll_time.value = val)
	v_scroll_time.value_changed.connect(func(val): v_scroll_names.value = val)

# Добавление канала (Track)
func add_channel(node_name: String, path: String, duration: float, type: String):
	# 1. Заголовок (TrackHeader)
	var track_header = TrackHeaderScene.instantiate()
	vbox_names.add_child(track_header)
	track_header.import_managers(selection_manager, time_pointer, context_menu_manager, self)
	track_header.setup(node_name, type)
	track_header.action_requested.connect(_on_track_action_requested)

	# 2. Контейнер сегментов (ControllerWrapper)
	var controller_wrapper = ControllerWrapperScene.instantiate()
	controller_wrapper.import_managers(selection_manager, time_pointer, context_menu_manager)
	vbox_timelines.add_child(controller_wrapper)

	controller_wrapper.node_name = node_name
	
	# Задаем базовые свойства (масштаб) 
	controller_wrapper.px_to_sec_ratio = px_to_sec_ratio 
	controller_wrapper.total_duration = duration # Передаем длительность файла дорожке
	
	controller_wrapper.import_initial_data(type, path)
	controller_wrapper.spawn_segment(node_name, 0.0, 0.0, duration, duration)
	#controller_wrapper.import_initial_data(type, path)
	
	# Подписываемся на изменения таймлайна 
	controller_wrapper.connect("size_changed", func(): timeline_changed.emit()) 
	
	timeline_changed.emit()


# Обработка контекстного меню трека
func _on_track_action_requested(id: int, idx: int, acapella_path: String):
	_active_idx = idx
	_on_menu_item_selected(id, acapella_path)
func _on_menu_item_selected(id: int, acapella_path: String = ""):
	if _active_idx == -1: return
	
	var header = vbox_names.get_child(_active_idx)
	var wrapper = vbox_timelines.get_child(_active_idx)
	
	Debugger.debug("id: " + str(id))
	match id:
		0: # Вверх
			if _active_idx > 0:
				vbox_names.move_child(header, _active_idx - 1)
				vbox_timelines.move_child(wrapper, _active_idx - 1)
		1: # Вниз
			if _active_idx < vbox_names.get_child_count() - 1:
				vbox_names.move_child(header, _active_idx + 1)
				vbox_timelines.move_child(wrapper, _active_idx + 1)
		2: # Vosk Menu - Acapella ONLY
			var whisper = UIManager.show_ui("WhisperHandler", self.get_parent())
			whisper.import_song_path(acapella_path)
			whisper.init_handler(wrapper)

		3: # Удалить
			header.queue_free()
			wrapper.queue_free()
			timeline_changed.emit()
	
	_active_idx = -1

# --- Экспорт новой конфигурации (Segments вместо Jumpers) ---
func export_project_configs() -> Dictionary:
	var export_data = {
		"files": {"acapella": {}, "instrumental": {}, "video": {}},
		"characters": []
	}
	
	for wrapper in vbox_timelines.get_children():
		if not wrapper.has_method("prepare_export_timecodes"): continue
		
		# Теперь вызываем экспорт сегментов (в секундах)
		var track_info = {
			"path": wrapper.initial_path,
			"segments": wrapper.prepare_export_timecodes()
		}
		
		match wrapper.node_type:
			"acapella":
				export_data["files"]["acapella"][wrapper.node_name] = track_info
				if not wrapper.node_name in export_data["characters"]:
					export_data["characters"].append(wrapper.node_name)
			"instrumental":
				export_data["files"]["instrumental"][wrapper.node_name] = track_info
			"video":
				# Для видео используем структуру с "videos" и общим списком "segments"
				if not export_data["files"]["video"].has("videos"):
					export_data["files"]["video"]["videos"] = {}
					export_data["files"]["video"]["segments"] = []
				
				export_data["files"]["video"]["videos"][wrapper.node_name] = {"path": wrapper.initial_path}
				export_data["files"]["video"]["segments"].append_array(track_info["segments"])
				
	return export_data

# --- Drag & Drop ---
func _notification(what):
	match what:
		NOTIFICATION_DRAG_BEGIN:
			if _is_valid_drag():
				drop_zone.visible = true
		NOTIFICATION_DRAG_END:
			drop_zone.visible = false


func _is_valid_drag() -> bool:
	var data = get_viewport().gui_get_drag_data()
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "media_file"

func _can_drop_data(_at_position, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "media_file"

func _drop_data(_pos, data):
	var type_str = "instrumental" 
	match int(data.track_type):
		2: type_str = "acapella"
		1: type_str = "video"
		_: type_str = "instrumental"
	
	add_channel(data.node_name, data.path, data.duration, type_str)

# Логика магнитного прилипания
func get_snapped_time(target_time: float, duration: float, ignore_node: Control) -> float:
	var snap_threshold = 0.3 # 0.3 секунды 
	var snap_points = [0.0]
	
	for wrapper in vbox_timelines.get_children():
		if not wrapper.has_method("get_segments"): continue
		for seg in wrapper.get_segments():
			if seg == ignore_node: continue
			snap_points.append(seg.timeline_start)
			snap_points.append(seg.timeline_start + seg.duration)
			
	for p in snap_points:
		if abs(target_time - p) < snap_threshold: return p
		if abs((target_time + duration) - p) < snap_threshold: return p - duration
			
	return target_time

func _on_time_pointer_moved(pointer_time: float) -> void:
	pass

func _on_timeline_move_requested(delta_move_in_pix: int) -> void:
	var new_h_scroll_value = timeline_scroll_container.scroll_horizontal + delta_move_in_pix
	timeline_scroll_container.scroll_horizontal = clamp(new_h_scroll_value, h_scroll.min_value, h_scroll.max_value)


func refresh_all_wrappers() -> void:
	for wrapper in vbox_timelines.get_children():
		if wrapper.has_method("sort_segments"):
			wrapper.sort_segments()
		if wrapper.has_method("_on_size_changed"): # Или как называется твоя функция обновления ширины
			wrapper._on_size_changed()


# Добавить в конец timeline.gd
func get_all_wrappers() -> Array[ControllerWrapper]:
	var wrappers: Array[ControllerWrapper] = []
	if vbox_timelines:
		for child in vbox_timelines.get_children():
			if child is ControllerWrapper:
				wrappers.append(child)
	return wrappers
