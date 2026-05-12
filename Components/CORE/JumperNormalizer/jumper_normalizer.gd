extends Node
class_name JumperNormalizer


static func build_jumper_map(jumpers: Array, lengths: Dictionary) -> Array:
	var segments := []
	var logic := 0.0
	var phys = jumpers[0].get("start_from", 0.0)
	var current_id = jumpers[0].get("id", null)

	## Adding start null-jumper
	segments.append({
		"id": "EMPTY",
		"logical_start": -PreferencesData.get_data("countdown_time"),
		"logical_end": 0.0,
		"physical_start": 0.0,
		"physical_end": 0.0,
		"jumper_index": 0
	})

	for i in range(1, jumpers.size()):
		var j = jumpers[i]
		var seg_id = ""
		if j.has("id"):
			seg_id = j["id"]
		else:
			seg_id = null

		if j.has("from_time"):
			var length = j["from_time"] - phys
			if length < 0:
				length = 0

			# main segment
			segments.append({
				"id": seg_id,
				"logical_start": logic,
				"logical_end": logic + length,
				"physical_start": phys,
				"physical_end": phys + length,
				"jumper_index": i
			})
			logic += length
			phys = j["to_time"]

			# repeats
			if j.has("repeats"):
				for _r in range(j["repeats"]):
					segments.append({
						"id": seg_id,
						"logical_start": logic,
						"logical_end": logic + length,
						"physical_start": phys,
						"physical_end": phys + length,
						"jumper_index": i
					})
					logic += length

		elif j.has("stop_at"):
			var end = j["stop_at"]
			if end == null:
				if lengths.has(seg_id):
					end = lengths.get(seg_id, 0.0)
				elif lengths.size() > 0:
					end = lengths.values()[0]
				else:
					end = 0.0

			var length = end - phys
			if length < 0:
				length = 0

			segments.append({
				"id": seg_id,
				"logical_start": logic,
				"logical_end": logic + length,
				"physical_start": phys,
				"physical_end": phys + length,
				"jumper_index": i
			})
			break

	return segments