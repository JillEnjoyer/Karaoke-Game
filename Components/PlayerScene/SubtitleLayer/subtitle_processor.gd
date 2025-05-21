extends Node

class_name SubtitleProcessor


func parse_vosk_json(json_string: String) -> Dictionary:
	var json_result = JSON.parse_string(json_string)
	if json_result == null or not json_result.has("result"):
		push_error("Invalid Vosk JSON format!")
		return {}
	return json_result


# 2. Extract all words into Dict
func extract_words(vosk_data: Dictionary) -> Array:
	var words = []
	for word_obj in vosk_data["result"]:
		words.append(word_obj["word"])
	return words


# 3. Get text variants
enum TextSource {
	AUTO_FROM_VOSK,
	USER_INPUT,
	ONLINE_SEARCH
}


# 4. Online text search
func fetch_lyrics_online(song_name: String) -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# API request
	var url = "https://api.genius.com/search?q=" + song_name.uri_encode()
	http_request.request(url)
	
	var result = await http_request.request_completed
	if result[1] != 200:
		return ""
	
	var json = JSON.parse_string(result[3].get_string_from_utf8())
	return json["response"]["hits"][0]["result"]["lyrics"] if json else ""


# 5. Texts comparison and timecode sync
func sync_text_with_timestamps(vosk_data: Dictionary, reference_text: String) -> Dictionary:
	var vosk_words = vosk_data["result"].duplicate(true)
	var ref_words = reference_text.to_lower().split(" ", false)
	
	var i = 0  # Vosk index
	var j = 0  # Reference text index
	var output = []
	var last_matched_index = -1
	
	while i < vosk_words.size() and j < ref_words.size():
		var vosk_word = vosk_words[i]["word"].to_lower()
		var ref_word = ref_words[j]
		
		# if words are similiar (threeshold 70%)
		if _words_similar(vosk_word, ref_word):
			output.append({
				"word": ref_words[j],  # take word from right place
				"start": vosk_words[i]["start"],
				"end": vosk_words[i]["end"],
				"conf": vosk_words[i]["conf"]
			})
			last_matched_index = i
			i += 1
			j += 1
		else:
			# Skip "false" word from Vosk
			i += 1
	
	# Add not taken words (if Vosk skipped words)
	while j < ref_words.size():
		if output.size() > 0:
			# Include with +- timecodes
			output.append({
				"word": ref_words[j],
				"start": output.back()["end"],
				"end": output.back()["end"] + 0.5,
				"conf": 0.5
			})
		j += 1
	
	return {"result": output, "text": reference_text}


func _words_similar(word1: String, word2: String, threshold: float = 0.7) -> bool:
	var distance = DistanceCounter.new()._levenshtein_distance(word1, word2)
	var max_len = max(word1.length(), word2.length())
	var similarity = 1.0 - float(distance) / max_len
	return similarity >= threshold


func save_to_vlsub(data: Dictionary, filename: String) -> void:
	var file = FileAccess.open(filename + ".vlsub", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
