extends RefCounted
class_name ConflictHandler

# Разрешает наложения (overlap) и микро-зазоры внутри ОДНОГО трека
static func resolve_track_conflicts(wrapper: Control) -> void:
	var segments = wrapper.get_segments()
	if segments.size() <= 1:
		return
		
	# Сортируем по времени начала на таймлайне
	segments.sort_custom(func(a, b): return a.timeline_start < b.timeline_start)
	
	for i in range(1, segments.size()):
		var prev = segments[i-1]
		var curr = segments[i]
		
		var prev_end = prev.timeline_start + prev.duration
		var gap = curr.timeline_start - prev_end
		
		# 1. Если наложение — выталкиваем вправо
		if gap < 0:
			curr.timeline_start = prev_end
			curr.update_visual_position()
		
		# 2. Если зазор слишком мал (магнит внутри трека) — приклеиваем
		elif gap > 0 and gap < 0.1: # bind_threshold
			curr.timeline_start = prev_end
			curr.update_visual_position()