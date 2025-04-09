extends Control

# num 0-x: "Name"
var id_objects: Dictionary = {}
# num 0-x: word instance
var word_objects: Dictionary = {}

var default = {
	"font_path": "res://Fonts/ComicSansMS.ttf",
	"font_size": 36,
	"font_color": Color(1, 1, 1)
}

@onready var default_WordCell_path = preload("res://PlayerScene/SubtitleLayer/WordCell.tscn")
var last_available_id = 0


func _ready() -> void:
	add_word("HELLO", Vector2(0.1, 0.2), Vector2(0.15, 0.05))
	await get_tree().create_timer(1).timeout
	add_word("WORLD", Vector2(0.3, 0.2), Vector2(0.15, 0.05))


func add_word(word: String, position: Vector2, size: Vector2) -> void:
	var current_word = default_WordCell_path.instantiate()
	
	var label = current_word.get_node("TextLayer")
	label.text = word
	
	current_word.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	current_word.anchor_left = position.x
	current_word.anchor_top = position.y
	current_word.anchor_right = position.x + size.x
	current_word.anchor_bottom = position.y + size.y
	
	current_word.size_flags_horizontal = Control.SIZE_FILL
	current_word.size_flags_vertical = Control.SIZE_FILL
	
	current_word.set_offsets_preset(Control.PRESET_MODE_MINSIZE, Control.PRESET_TOP_LEFT)
	
	word_objects[last_available_id] = current_word
	id_objects[last_available_id] = word
	
	add_child(current_word)
	last_available_id += 1


func remove_word(word: String) -> void:
	var id = get_id(word)
	if id == -1:
		push_warning("Word not found: %s" % word)
		return
	
	if word_objects.has(id):
		var object = word_objects[id]
		remove_child(object)
		object.queue_free()
		word_objects.erase(id)
		id_objects.erase(id)


func get_id(word: String) -> int:
	for id in id_objects:
		if id_objects[id] == word:
			return id
	return -1


func get_object(word: String) -> Control:
	var id = get_id(word)
	return word_objects.get(id)


func clear_all_words() -> void:
	for word in id_objects.values():
		remove_word(word)
	word_objects.clear()
	id_objects.clear()
	last_available_id = 0
