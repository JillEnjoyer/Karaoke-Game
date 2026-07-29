extends Node
#class_name WhisperNTextComparisor

const DEFAULT_STYLE = {
	"color": "#FFFFFF",
	"font_size": 24,
	"font_type": "Arial",
	"bold": true,
	"italic": false,
	"mask": "maskObject1"
}

static var _word_clean_regex: RegEx = null

# Вспомогательный класс для хранения данных о слове до сборки строк
class AlignItem:
	var clean_word: String
	var line_index: int
	var whisper_match: Dictionary # Если null/пустой - слово не распознано
	
	func _init(cw: String, li: int):
		clean_word = cw
		line_index = li
		whisper_match = {}

static func align_text_with_whisper(original_text: String, whisper_data: Array) -> Array:
	if _word_clean_regex == null:
		_word_clean_regex = RegEx.new()
		_word_clean_regex.compile("[^a-zA-Z0-9а-яА-ЯёЁ]")

	var whisper_words = []
	for phrase in whisper_data:
		if phrase is Dictionary:
			var source_words = phrase.get("words", phrase.get("result", []))
			for w in source_words:
				whisper_words.append(w)

	if whisper_words.size() == 0:
		push_warning("[Comparer] No words from Whisper for alignment.")
		return []

	# Parsing text and getting line indexes
	var lines = original_text.split("\n", false)
	var clean_items: Array[AlignItem] = []
	
	for line_idx in range(lines.size()):
		var line_text = lines[line_idx].strip_edges()
		if line_text == "": continue
		var raw_words = line_text.split(" ")
		for rw in raw_words:
			if _clean_word(rw) != "":
				clean_items.append(AlignItem.new(rw, line_idx))

	if clean_items.size() == 0: return []

	# Global alignment (Needleman-Wunsch DP)
	var n = clean_items.size()
	var m = whisper_words.size()
	
	var dp = []
	for i in range(n + 1):
		var row = []
		row.resize(m + 1)
		row.fill(0.0)
		dp.append(row)
		
	var gap_penalty = -1.0
	for i in range(1, n + 1): dp[i][0] = i * gap_penalty
	for j in range(1, m + 1): dp[0][j] = j * gap_penalty

	for i in range(1, n + 1):
		for j in range(1, m + 1):
			var cw = _clean_word(clean_items[i-1].clean_word)
			var ww = _clean_word(whisper_words[j-1].get("word", ""))
			
			var match_score = -1.0
			if cw == ww:
				match_score = 2.0
			elif _are_words_similar(cw, ww):
				match_score = 1.0
				
			var match = dp[i-1][j-1] + match_score
			var delete = dp[i-1][j] + gap_penalty
			var insert = dp[i][j-1] + gap_penalty
			
			dp[i][j] = max(match, max(delete, insert))

	# BACKTRACKING
	var i = n
	var j = m
	
	while i > 0 and j > 0:
		var current_score = dp[i][j]
		var cw = _clean_word(clean_items[i-1].clean_word)
		var ww = _clean_word(whisper_words[j-1].get("word", ""))
		
		var match_score = -1.0
		if cw == ww: match_score = 2.0
		elif _are_words_similar(cw, ww): match_score = 1.0
		
		if current_score == dp[i-1][j-1] + match_score:
			if match_score > 0:
				clean_items[i-1].whisper_match = whisper_words[j-1]
			i -= 1
			j -= 1
		elif current_score == dp[i-1][j] + gap_penalty:
			i -= 1
		else:
			j -= 1

	# Preparing raw words
	var line_entries_map = {}
	for idx in range(lines.size()):
		line_entries_map[idx] = []
		
	var raw_flat_entries = []
	for item in clean_items:
		var entry = {
			"word": item.clean_word,
			"start_time": -1.0,
			"end_time": -1.0,
			"conf": 0.1,
			"character": "",
			"is_anchor": false,
			"line_index": item.line_index
		}
		if not item.whisper_match.is_empty():
			entry["start_time"] = float(item.whisper_match.get("start_time", 0.0))
			entry["end_time"] = float(item.whisper_match.get("end_time", 0.0))
			entry["conf"] = float(item.whisper_match.get("conf", 1.0))
			entry["is_anchor"] = true
			
		raw_flat_entries.append(entry)

	# Time interpolation
	# Getting very first and last song anchors
	var first_anchor_idx = -1
	var last_anchor_idx = -1
	for idx in range(raw_flat_entries.size()):
		if raw_flat_entries[idx]["is_anchor"]:
			if first_anchor_idx == -1: first_anchor_idx = idx
			last_anchor_idx = idx

	# Closing dead zone in the beginning (before the first anchor)
	if first_anchor_idx > 0:
		var first_anchor_start = raw_flat_entries[first_anchor_idx]["start_time"]
		var step = 0.65 # Step in case of missing anchors
		
		# Giving [EXAMPLE 0.65 sec] from first found word
		var current_time = first_anchor_start
		for idx in range(first_anchor_idx - 1, -1, -1):
			current_time -= step
			if current_time < 0.0:
				current_time = 0.0
			raw_flat_entries[idx]["start_time"] = current_time
			raw_flat_entries[idx]["end_time"] = current_time + (step * 0.9)
			raw_flat_entries[idx]["conf"] = 0.4
		
		# in case there is too much words that are close to 0.0,
		# Need to normalize positioning between 0.0 and the first anchor
		var last_t = 0.0
		var sub_gap = first_anchor_start / float(first_anchor_idx + 1)
		if (first_anchor_start - current_time) < 0.1 or current_time == 0.0:
			for idx in range(first_anchor_idx):
				raw_flat_entries[idx]["start_time"] = last_t + (sub_gap * 0.1)
				raw_flat_entries[idx]["end_time"] = last_t + sub_gap
				last_t = raw_flat_entries[idx]["end_time"]

	# Base interpolation between anchors
	var ptr = 0
	while ptr < raw_flat_entries.size():
		if raw_flat_entries[ptr]["is_anchor"] or ptr < first_anchor_idx:
			ptr += 1
			continue
			
		var missing_count = 0
		var prev_anchor_end = 0.0
		if ptr > 0:
			prev_anchor_end = raw_flat_entries[ptr - 1]["end_time"]
			
		var next_anchor_start = prev_anchor_end + 1.0
		
		while (ptr + missing_count) < raw_flat_entries.size() and not raw_flat_entries[ptr + missing_count]["is_anchor"]:
			missing_count += 1
			
		if (ptr + missing_count) < raw_flat_entries.size():
			next_anchor_start = raw_flat_entries[ptr + missing_count]["start_time"]
			
		var gap_duration = next_anchor_start - prev_anchor_end
		if gap_duration <= 0: gap_duration = 0.2
		
		var time_per_word = gap_duration / float(missing_count + 1)
		
		for ms in range(missing_count):
			var curr_idx = ptr + ms
			var w_start = prev_anchor_end + (time_per_word * (ms + 1))
			raw_flat_entries[curr_idx]["start_time"] = w_start
			raw_flat_entries[curr_idx]["end_time"] = w_start + (time_per_word * 0.9)
			raw_flat_entries[curr_idx]["conf"] = 0.4
			
		ptr += missing_count

	# Fixing Dead zone at the end (after the last fully recognized word)
	if last_anchor_idx != -1 and last_anchor_idx < raw_flat_entries.size() - 1:
		var last_time = raw_flat_entries[last_anchor_idx]["end_time"]
		var step = 0.6
		for idx in range(last_anchor_idx + 1, raw_flat_entries.size()):
			raw_flat_entries[idx]["start_time"] = last_time + 0.05
			raw_flat_entries[idx]["end_time"] = last_time + step
			last_time = raw_flat_entries[idx]["end_time"]
			raw_flat_entries[idx]["conf"] = 0.4

	# Word distribution in original lines
	for entry in raw_flat_entries:
		var l_idx = entry["line_index"]
		entry.erase("is_anchor")
		entry.erase("line_index")
		line_entries_map[l_idx].append(entry)

	# Final JSON
	var final_result = []
	for line_idx in range(lines.size()):
		var line_text = lines[line_idx].strip_edges()
		if line_text == "": continue
		
		var words_in_line = line_entries_map.get(line_idx, [])
		if words_in_line.size() == 0: continue
		
		var line_struct = {
			"character": "all",
			"is_extended": false,
			"text": line_text,
			"start_time": words_in_line[0]["start_time"],
			"end_time": words_in_line[-1]["end_time"],
			"style": DEFAULT_STYLE.duplicate(),
			"words": words_in_line
		}
		final_result.append(line_struct)
			
	return final_result


static func _clean_word(w: String) -> String:
	return _word_clean_regex.sub(w, "", true).to_lower()

static func _are_words_similar(w1: String, w2: String) -> bool:
	if w1 == w2 and w1 != "": return true
	if w1.length() >= 3 and w2.length() >= 3:
		if w1.begins_with(w2) or w2.begins_with(w1):
			return true
	return false
