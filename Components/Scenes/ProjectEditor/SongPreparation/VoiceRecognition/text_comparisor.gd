extends Node
class_name TextComparisor

const DEFAULT_STYLE = {
	"color": "#FFFFFF",
	"font_size": 24,
	"font_type": "Arial",
	"bold": true,
	"italic": false,
	"mask": "maskObject1"
}


static func align_text_with_vosk(original_text: String, vosk_raw_output: String) -> Array:
	var final_result = []
	
	# Ignore Vosk logs
	var json_start = vosk_raw_output.find("[")
	if json_start == -1:
		push_error("JSON не найден в выводе Vosk!")
		return []
	
	var clean_json = vosk_raw_output.substr(json_start)
	
	var json = JSON.new()
	var error = json.parse(clean_json)
	if error != OK:
		push_error("Ошибка парсинга JSON: ", json.get_error_message(), " на строке ", json.get_error_line())
		return []
	
	var vosk_data = json.data
	var vosk_words = []
	
	# Every word to a flat list
	for block in vosk_data:
		if block is Dictionary and block.has("result"):
			for w in block["result"]:
				vosk_words.append(w)
				
	if vosk_words.size() == 0:
		push_warning("Vosk не распознал ни одного слова.")

	var lines = original_text.split("\n", false)
	var current_vosk_idx = 0
	
	for raw_line in lines:
		var line_text = raw_line.strip_edges()
		if line_text == "": continue
		
		var line_struct = {
			"character": "Unknown", 
			"timestamp": {"start": 0.0, "end": 0.0},
			"line": line_text,
			"words": []
		}
		
		var words_in_line = line_text.split(" ", false)
		
		for orig_word in words_in_line:
			var clean_orig = _clean_word(orig_word)
			var matched_word_data = null
			
			# Search window up to 20 words ahead
			var search_limit = min(current_vosk_idx + 20, vosk_words.size())
			for i in range(current_vosk_idx, search_limit):
				var clean_vosk = _clean_word(vosk_words[i]["word"])
				
				if _are_words_similar(clean_orig, clean_vosk):
					matched_word_data = vosk_words[i]
					current_vosk_idx = i + 1
					break
			
			var word_entry = {
				"word": orig_word,
				"start": 0.0,
				"end": 0.0,
				"style": DEFAULT_STYLE.duplicate()
			}
			
			if matched_word_data:
				word_entry["start"] = matched_word_data["start"]
				word_entry["end"] = matched_word_data["end"]
			else:
				# If word isnt found, estimate timings
				var prev_end = 0.0
				if line_struct["words"].size() > 0:
					prev_end = line_struct["words"].back()["end"]
				elif final_result.size() > 0:
					prev_end = final_result.back()["timestamp"]["end"]
				
				word_entry["start"] = prev_end + 0.05
				word_entry["end"] = prev_end + 0.35
			
			line_struct["words"].append(word_entry)

		if line_struct["words"].size() > 0:
			line_struct["timestamp"]["start"] = line_struct["words"][0]["start"]
			line_struct["timestamp"]["end"] = line_struct["words"].back()["end"]
			final_result.append(line_struct)
			
	return final_result


static func _clean_word(w: String) -> String:
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9]")
	return regex.sub(w.to_lower(), "", true)


# Simplified similarity check
## TODO: Connect to levenshtein distance static method
static func _are_words_similar(a: String, b: String) -> bool: 
	if a == b: return true
	if a.length() > 3 and (a.contains(b) or b.contains(a)): return true
	if abs(a.length() - b.length()) <= 2:
		return true
	return false
