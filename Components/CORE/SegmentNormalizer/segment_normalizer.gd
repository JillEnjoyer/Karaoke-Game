extends Node
class_name SegmentNormalizer

static func build_segment_map(segments_data: Array, lengths: Dictionary) -> Array:
	var normalized := []
	var logic := 0.0


	for i in range(segments_data.size()):
		Debugger.debug("seg: " + str(segments_data[i]))
		var seg = segments_data[i]
		var res_id = seg.get("id", null) # Ищем ID ресурса (Original, Bonus и т.д.)
		
		var phys_start = seg.get("start", 0.0)
		var phys_end = seg.get("end", null)
		
		# 2. Если 'end' не указан (null), ищем длину конкретного ресурса в словаре
		if phys_end == null:
			if res_id != null and lengths.has(res_id):
				phys_end = lengths[res_id]
			elif lengths.size() > 1 and res_id == null:
				# Если ID не указан, но файлов много — это ошибка конфига, 
				# берем первый попавшийся или 0
				phys_end = lengths.values()[0] 
			else:
				# Для аудио случая, где в словаре всего одна запись
				phys_end = lengths.get(res_id, lengths.values()[0] if lengths.size() > 0 else 0.0)
		
		var length = max(0.0, phys_end - phys_start)
		var total_plays = 1 + seg.get("repeats", 0)
		
		# 3. Разворачиваем повторы в линейную последовательность
		for r in range(total_plays):
			normalized.append({
				"id": res_id,
				"logical_start": logic,
				"logical_end": logic + length,
				"physical_start": phys_start,
				"physical_end": phys_end,
				"segment_index": i
			})
			logic += length

	Debugger.debug("normalized: " + str(normalized))
	return normalized