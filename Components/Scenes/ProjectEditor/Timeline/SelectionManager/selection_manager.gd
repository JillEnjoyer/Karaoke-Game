extends Node
class_name SelectionManager

@onready var timeline: Control = get_parent()
var selected_segments: Array = []

# Подключаем сигналы к каждому новому контроллеру
func connect_segment_signals(seg: OffsetController) -> void:
	if not seg.selection_requested.is_connected(_on_segment_selection_requested):
		seg.selection_requested.connect(_on_segment_selection_requested)
		seg.drag_started.connect(_on_segment_drag_started)
		seg.drag_processed.connect(_on_segment_drag_processed)
		seg.drag_ended.connect(_on_segment_drag_ended)
		seg.context_menu_requested.connect(_on_segment_context_menu_requested)

# --- ЛОГИКА ВЫДЕЛЕНИЯ ---
func _on_segment_selection_requested(seg: OffsetController, ctrl_pressed: bool) -> void:
	if ctrl_pressed:
		if selected_segments.has(seg):
			_unregister_selection(seg)
		else:
			_register_selection(seg)
	else:
		if not selected_segments.has(seg):
			_clear_selection_except(seg)
			_register_selection(seg)

func _register_selection(seg: OffsetController) -> void:
	if not selected_segments.has(seg):
		selected_segments.append(seg)
		seg.set_selected(true)

func _unregister_selection(seg: OffsetController) -> void:
	if selected_segments.has(seg):
		selected_segments.erase(seg)
		seg.set_selected(false)

func _clear_selection_except(exception: OffsetController = null) -> void:
	var to_clear = selected_segments.duplicate()
	for seg in to_clear:
		if seg != exception:
			_unregister_selection(seg)

# --- МУЛЬТИ-ПЕРЕТАСКИВАНИЕ ---
func _on_segment_drag_started() -> void:
	for seg in selected_segments:
		seg.initial_timeline_start = seg.timeline_start
		seg.initial_source_start = seg.source_start
		seg.initial_duration = seg.duration

func _on_segment_drag_processed(master_node: OffsetController, delta_sec: float) -> void:
	if not selected_segments.has(master_node): return
	
	if master_node.drag_mode == "move":
		# 1. Двигаем и магнитим Лидера
		var target = master_node.initial_timeline_start + delta_sec
		master_node.timeline_start = timeline.get_snapped_time(target, master_node.duration, master_node)
		master_node.update_visual_position()
		
		# 2. Высчитываем чистую дельту лидера (после магнита)
		var effective_delta = master_node.timeline_start - master_node.initial_timeline_start
		
		# 3. Применяем чистую дельту ко всем остальным
		for seg in selected_segments:
			if seg == master_node: continue
			seg.timeline_start = seg.initial_timeline_start + effective_delta
			seg.update_visual_position()
	else:
		# Если это обрезка (trimming ручками left/right), позволяем клипу менять себя локально
		master_node.apply_local_trim(delta_sec)

func _on_segment_drag_ended() -> void:
	timeline.refresh_all_wrappers()
	timeline.emit_signal("timeline_changed")

# --- ПАКЕТНЫЕ ОПЕРАЦИИ (ContextMenu) ---
func _on_segment_context_menu_requested(seg: OffsetController, global_mouse_pos: Vector2, local_x: float) -> void:
	# Если кликнули ПКМ без выделения - выделяем только его
	if not selected_segments.has(seg):
		_clear_selection_except(seg)
		_register_selection(seg)
		
	var exact_cut_time = seg.timeline_start + (local_x / seg.px_to_sec_ratio)
	
	timeline.context_menu_manager.show_menu(
		global_mouse_pos,
		["Разрезать выбранные", "Дублировать", "Удалить"],
		func(id):
			match id:
				0: batch_split(exact_cut_time)
				1: batch_duplicate()
				2: batch_delete()
	)

func batch_delete() -> void:
	var to_delete = selected_segments.duplicate()
	_clear_selection_except(null)
	for seg in to_delete:
		if is_instance_valid(seg):
			var wrapper = seg.get_parent()
			if wrapper and "segments" in wrapper:
				wrapper.segments.erase(seg)
			seg.queue_free()
	
	await timeline.get_tree().process_frame
	timeline.refresh_all_wrappers()
	timeline.emit_signal("timeline_changed")

func batch_split(cut_time: float) -> void:
	var to_split = selected_segments.duplicate()
	for seg in to_split:
		if is_instance_valid(seg):
			if cut_time > seg.timeline_start and cut_time < (seg.timeline_start + seg.duration):
				var split_delta = cut_time - seg.timeline_start
				
				var new_timeline_start = seg.timeline_start + split_delta
				var new_source_start = seg.source_start + split_delta
				var new_duration = seg.duration - split_delta
				
				seg.duration = split_delta
				seg.update_visual_position()
				
				var wrapper = seg.get_parent()
				# ПРОВЕРКА: Если у твоего враппера функция называется spawn_segment:
				if wrapper and wrapper.has_method("spawn_segment"):
					wrapper.spawn_segment(seg.source_id, new_timeline_start, new_source_start, new_duration, seg.file_total_duration)
					
	await timeline.get_tree().process_frame
	timeline.refresh_all_wrappers()
	timeline.emit_signal("timeline_changed")

func batch_duplicate() -> void:
	var to_duplicate = selected_segments.duplicate()
	_clear_selection_except(null)
	for seg in to_duplicate:
		if is_instance_valid(seg):
			var wrapper = seg.get_parent()
			if wrapper and wrapper.has_method("spawn_segment"):
				var dup_timeline_start = seg.timeline_start + seg.duration
				var new_seg = wrapper.spawn_segment(seg.source_id, dup_timeline_start, seg.source_start, seg.duration, seg.file_total_duration)
				if new_seg:
					_register_selection(new_seg)
					
	await timeline.get_tree().process_frame
	timeline.refresh_all_wrappers()
	timeline.emit_signal("timeline_changed")
