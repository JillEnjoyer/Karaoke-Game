extends Control

# num 0-x: "Name"
var id_objects: Dictionary = {}
# num 0-x: path
var word_objects: Dictionary = {}

#@onready var main_HBox = $HBoxContainer

var default = {
	"default_font_path" = "res://Fonts/ComicSansMS.ttf",
	"default_font_size" = 36,
	"default_font_color" = Color(1, 1, 1)
}
@onready var default_WordCell_path = preload("res://PlayerScene/SubtitleLayer/WordCell.tscn")

var last_avaliable_id = 0

func _ready() -> void:
	# add_word(word, position, size, font_size, hbox)
	add_word("Привет", Vector2(0.1, 0.2), Vector2(0.015, 0.020), 1)
	add_word("Мир", Vector2(0.30, 0.20), Vector2(0.015, 0.020), 1)


func add_word(word: String, position: Vector2, size: Vector2, font_size: int) -> void:
	position = PreferencesData.percent_to_pixels(position)
	size = PreferencesData.percent_to_pixels(size)
	print(str(position) + str(size))
	var current_word = default_WordCell_path.instantiate()
	
	current_word.get_node("TextLayer").text = word
	current_word.position = position
	current_word.size = size
	
	word_objects[last_avaliable_id] = current_word
	id_objects[last_avaliable_id] = word
	
	add_child(current_word)
	last_avaliable_id += 1


func remove_word(word: String) -> void:
	var id = get_id(word)
	print("remove_word = " + str(id))
	if id == -1:
		print("Word not found: ", word)
		return
	
	if id in word_objects:
		var object = word_objects[id]
		remove_child(object)
		object.queue_free()
		word_objects.erase(id)
		id_objects.erase(id)
		print("Word removed: ", word, ", ID: ", id)
	else:
		print("Object not found for ID: ", id)


func get_id(word: String) -> int:
	var searchable_id = 0
	for id in id_objects.keys():
		if id_objects[id] == word:
			return id
		searchable_id += 1
	return -1


func get_object(word: String):
	var id = get_id(word)
	
	return word_objects[id]


func clear_all_words() -> void:
	var local_id_objects = id_objects.duplicate()
	for id in local_id_objects:
		print(id)
		print(local_id_objects[id])
		remove_word(id_objects[id])
	word_objects.clear()
	id_objects.clear()
	last_avaliable_id = 0
