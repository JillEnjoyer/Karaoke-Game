extends Control
class_name KaraokeStyleLine

@export var max_width := 1600
@export var line_height := 100

@onready var left_panel: VBoxContainer = $HBoxContainer/LeftPanel
@onready var avatar_rect: TextureRect = $HBoxContainer/LeftPanel/AvatarRect
@onready var name_label: Label = $HBoxContainer/LeftPanel/NameLabel
@onready var words_container: Control = $HBoxContainer/WordsContainer
@onready var local_jumper: Control = $HBoxContainer/WordsContainer/WordJumper

enum JumperState { HIDDEN, ENTERING, ACTIVE, FALLING, DONE }
var j_state: JumperState = JumperState.HIDDEN
var fall_distance := 800.0 # Дистанция вылета/падения

var character: String = ""
var start_time: float = 0.0
var end_time: float = 0.0
var word_cells := []

var current_word_index := -1
var jump_tween: Tween

func _ready() -> void:
	if local_jumper:
		local_jumper.modulate.a = 0.0

func setup(character_name: String, words: Array, line_start: float, line_end: float, display_mode: String) -> void:
	character = character_name
	start_time = line_start
	end_time = line_end
	
	_clear_words()
	_setup_role_ui(character_name, display_mode)
	_create_words(words)

func _setup_role_ui(char_name: String, mode: String) -> void:
	if mode == "hidden" or char_name == "all" or char_name == "":
		left_panel.visible = false
		return
		
	left_panel.visible = true
	
	var path = "res://Assets/Avatars/" + char_name + ".png"
	if ResourceLoader.exists(path):
		avatar_rect.texture = load(path)
	else:
		avatar_rect.texture = load("res://icon.svg") 
		
	match mode:
		"show_names":
			name_label.text = char_name
		"show_numbers":
			name_label.text = "P_" + str(abs(char_name.hash()) % 4 + 1)

func _create_words(words: Array) -> void:
	var current_x := 0
	var current_y := 0
	var space_size := 20
	
	for word_data in words:
		var cell = UIManager.get_desired_node("WordCell").instantiate()
		words_container.add_child(cell)
		
		var style = word_data.get("style", {})
		cell.set_word(word_data.get("word", ""), style)
		
		if current_x > 0 and current_x + cell.size.x > max_width:
			current_x = 0
			current_y += line_height
		
		cell.position = Vector2(current_x, current_y)
		
		word_cells.append({
			"cell": cell,
			"position": cell.position,
			"size": cell.size,
			"start": word_data.get("start_time", 0.0),
			"end": word_data.get("end_time", 0.0)
		})
		
		current_x += cell.size.x + space_size

func update_time(audio_time: float) -> void:
	if j_state == JumperState.DONE:
		return
		
	if audio_time > end_time:
		if j_state == JumperState.ACTIVE or j_state == JumperState.ENTERING:
			_play_looney_tunes_fall()
			# Гасим последнее подсвеченное слово при уходе строки
			if current_word_index != -1 and current_word_index < word_cells.size():
				word_cells[current_word_index]["cell"].set_highlight(false)
		return
		
	if audio_time < start_time:
		return

	var active_word_idx := -1
	for i in range(word_cells.size()):
		if audio_time >= word_cells[i]["start"] and audio_time <= word_cells[i]["end"]:
			active_word_idx = i
			break
			
	if active_word_idx != -1:
		var target_cell = word_cells[active_word_idx]
		var target_pos = target_cell["position"] + Vector2(target_cell["size"].x / 2.0, -30)
		
		# --- БЕЗОПАСНАЯ ЛОГИКА ПОДСВЕТКИ И ПОДПРЫГИВАНИЯ СЛОВА ---
		if active_word_idx != current_word_index:
			# 1. Моментально тушим и сбрасываем СТАРОЕ слово в исходную позицию при отталкивании
			if current_word_index != -1 and current_word_index < word_cells.size():
				word_cells[current_word_index]["cell"].set_highlight(false)
			
			var cell_to_highlight = target_cell["cell"]
			var check_index = active_word_idx # запоминаем для проверки в таймере
			
			if j_state == JumperState.HIDDEN:
				# Если вылетает снизу, подсвечиваем на 0.3с
				get_tree().create_timer(0.3).timeout.connect(func():
					# Проверяем, что за время таймера это слово все еще актуально
					if is_instance_valid(cell_to_highlight) and current_word_index == check_index:
						cell_to_highlight.set_highlight(true)
				)
			else:
				# Бьем по слову ровно в момент приземления (0.15с)!
				get_tree().create_timer(0.15).timeout.connect(func():
					if is_instance_valid(cell_to_highlight) and current_word_index == check_index:
						cell_to_highlight.set_highlight(true)
				)
		# ----------------------------------------------------

		if j_state == JumperState.HIDDEN:
			current_word_index = active_word_idx
			_play_entrance(target_pos)
		elif j_state == JumperState.ACTIVE and active_word_idx != current_word_index:
			current_word_index = active_word_idx
			_jump_to_pos(target_pos)

# ЭФФЕКТ 1: Вылет из-под экрана
func _play_entrance(target_pos: Vector2) -> void:
	if not local_jumper: return
	j_state = JumperState.ENTERING
	
	local_jumper.modulate.a = 1.0
	local_jumper.position = Vector2(target_pos.x, target_pos.y + fall_distance) 
	
	if jump_tween: jump_tween.kill()
	jump_tween = create_tween()
	
	jump_tween.tween_property(local_jumper, "position", target_pos, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	jump_tween.tween_callback(func(): j_state = JumperState.ACTIVE)

# ЭФФЕКТ 2: Прыжки по словам
func _jump_to_pos(target_pos: Vector2) -> void:
	if not local_jumper: return
	
	if jump_tween: jump_tween.kill()
	jump_tween = create_tween().set_parallel(true)
	
	jump_tween.tween_property(local_jumper, "position:x", target_pos.x, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var y_tween = create_tween()
	y_tween.tween_property(local_jumper, "position:y", target_pos.y - 40, 0.07)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(local_jumper, "position:y", target_pos.y, 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# ЭФФЕКТ 3: Looney Tunes падение
func _play_looney_tunes_fall() -> void:
	if not local_jumper: return
	j_state = JumperState.FALLING
	
	if jump_tween: jump_tween.kill()
	jump_tween = create_tween()
	
	var current_pos = local_jumper.position
	
	jump_tween.tween_property(local_jumper, "position:y", current_pos.y - 20, 0.25)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	jump_tween.tween_interval(0.2)
	
	jump_tween.tween_property(local_jumper, "position:y", current_pos.y + fall_distance, 0.35)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		
	jump_tween.tween_callback(func(): 
		local_jumper.modulate.a = 0.0
		j_state = JumperState.DONE
	)

func _clear_words() -> void:
	current_word_index = -1
	for item in word_cells:
		if is_instance_valid(item["cell"]):
			item["cell"].queue_free()
	word_cells.clear()
