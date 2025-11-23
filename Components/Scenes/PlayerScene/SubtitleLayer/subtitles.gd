extends Control
signal subtitles_finished

@onready var markers := [
	$CurrentLineMarker,
	$SecondLineMarker,
	$ThirdLineMarker,
	$LastLineMarker
] as Array[Node2D]
@onready var word_jumper = $WordJumper
var subtitle_math = SubtitleMath.new()
var subtitle_parser = SubtitleParser.new()

const LINE_COUNT := 4
const LINE_SLIDE_DURATION := 0.5
const JUMP_ADVANCE_TIME := 0.1
const BASE_JUMP_HEIGHT := 150.0
const JUMP_OVERSHOOT := 1.8
const JUMP_DURATION_SCALE := 0.9

var lines: Array = []
var subtitle_list: Array = []
var current_time: float = 0.0
var current_index: int = 0
var is_playing: bool = false
var jump_active: bool = false

func _ready() -> void:
	word_jumper.modulate.a = 0
	word_jumper.scale = Vector2(0.8, 0.8)
	
	for i in range(LINE_COUNT):
		_create_line(i)
	
	if not subtitle_list.is_empty():
		await get_tree().process_frame
		_position_all_lines()
		lines[0].modulate.a = 1.0

func init(path: String, type: String = "Karaoke") -> void:
	subtitle_list = subtitle_parser._load_subtitles(path)
	if subtitle_list.is_empty():
		return
	
	for i in range(min(LINE_COUNT, subtitle_list.size())):
		_setup_line(i)
	
	_position_all_lines()


func _create_line(index: int) -> void:
	var line := UIManager.show_ui("karaoke_style_line", self) as Control
	line.position = Vector2(
		markers.back().position.x - (line.size.x / 2),
		get_viewport().get_visible_rect().size.y + 100
	)
	lines.append(line)

func _setup_line(line_index: int) -> void:
	var data_index := current_index + line_index
	if data_index >= subtitle_list.size():
		lines[line_index].clear()
		return
	
	var data: Dictionary = subtitle_list[data_index]
	lines[line_index].setup(
		data.get("character", ""),
		data.get("words", []),
		data.get("timestamp", {}).get("start", 0.0),
		data.get("timestamp", {}).get("end", 0.0)
	)

func _position_all_lines() -> void:
	var tweens := create_tween().set_parallel(true)
	tweens.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	for i in range(min(LINE_COUNT, lines.size())):
		var target := markers[i].position - Vector2(lines[i].size.x / 2, 0)
		tweens.tween_property(lines[i], "position", target, LINE_SLIDE_DURATION * 0.8)
		
		lines[i].scale = Vector2(1.1, 1.1)
		tweens.tween_property(lines[i], "scale", Vector2.ONE, LINE_SLIDE_DURATION)

func _process(delta: float) -> void:
	if not is_playing or lines.is_empty():
		return
	
	current_time += delta
	
	if current_time >= lines[0].end_time:
		_advance_lines()
	
	if not jump_active and current_time >= lines[0].start_time - JUMP_ADVANCE_TIME:
		_start_jumping()

func _advance_lines() -> void:
	current_index += 1
	
	var old_line = lines.pop_front()
	old_line.queue_free()
	
	_create_line(LINE_COUNT - 1)
	_setup_line(LINE_COUNT - 1)
	
	_position_all_lines()
	
	if current_index >= subtitle_list.size():
		emit_signal("subtitles_finished")
		return
	
	jump_active = false

func _start_jumping() -> void:
	jump_active = true
	
	var appear_tween := create_tween()
	appear_tween.tween_property(word_jumper, "modulate:a", 1.0, 0.3)
	appear_tween.parallel().tween_property(word_jumper, "scale", Vector2.ONE, 0.3)
	await appear_tween.finished
	
	var start_pos := Vector2(
		markers[0].position.x - 120,
		markers[0].position.y - 30
	)
	
	await _animate_jump(word_jumper.global_position, start_pos, 0.6, 
					   BASE_JUMP_HEIGHT * 1.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
	
	var words = lines[0].get_word_positions()
	if words.is_empty():
		return
	
	var first_word_pos := _calculate_word_position(words[0])
	await _animate_jump(
		word_jumper.global_position, 
		first_word_pos, 
		words[0]["start"] - lines[0].start_time,
		BASE_JUMP_HEIGHT * 2.0,
		Tween.TRANS_BACK,
		Tween.EASE_OUT,
		true
	)
	
	for i in range(1, words.size()):
		var duration = max(words[i]["start"] - words[i-1]["end"], 0.1)
		var word_pos = _calculate_word_position(words[i])
		
		await _animate_jump(
			word_jumper.global_position,
			word_pos,
			duration,
			BASE_JUMP_HEIGHT,
			Tween.TRANS_BACK,
			Tween.EASE_OUT
		)
	
	await _final_jump_sequence()


func _calculate_word_position(word_data: Dictionary) -> Vector2:
	return lines[0].global_position + Vector2(
		word_data["position"].x + word_data["size"].x / 2,
		word_data["position"].y
	) - Vector2(word_jumper.size.x / 2, word_jumper.size.y)


func _animate_jump(
	from: Vector2, 
	to: Vector2, 
	duration: float, 
	height: float,
	trans: int = Tween.TRANS_LINEAR,
	ease_type: int = Tween.EASE_IN_OUT,
	is_first_jump: bool = false
) -> void:
	var tween := create_tween()
	tween.set_trans(trans).set_ease(ease_type)
	
	var control_point := (from + to) * 0.5 - Vector2(0, height * JUMP_OVERSHOOT)
	
	tween.tween_method(
		func(t: float):
			word_jumper.global_position = subtitle_math._quadratic_bezier(from, control_point, to, t),
		0.0, 1.0, duration * JUMP_DURATION_SCALE
	)
	
	if is_first_jump:
		tween.parallel().tween_property(word_jumper, "scale:x", 1.1, duration * 0.2)
		tween.parallel().tween_property(word_jumper, "scale:y", 0.8, duration * 0.2)
		tween.parallel().tween_property(word_jumper, "scale", Vector2.ONE, duration * 0.3) \
			.set_delay(duration * 0.7)
	else:
		tween.parallel().tween_property(word_jumper, "scale", 
			Vector2(1.2, 0.8), duration * 0.3)
		tween.parallel().tween_property(word_jumper, "scale", 
			Vector2.ONE, duration * 0.7).set_delay(duration * 0.3)
	
	await tween.finished

func _final_jump_sequence() -> void:
	var target_pos = lines[0].global_position + Vector2(
		lines[0].size.x + 100,
		lines[0].size.y / 2
	)
	var overshoot_pos = target_pos + Vector2(50, -120)
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	tween.tween_method(
		func(t: float):
			word_jumper.global_position = subtitle_math._quadratic_bezier(
				word_jumper.global_position, overshoot_pos, target_pos, t
			),
		0.0, 1.0, 0.7
	)
	
	tween.parallel().tween_property(word_jumper, "rotation", deg_to_rad(-20), 0.35)
	tween.parallel().tween_property(word_jumper, "rotation", 0.0, 0.35).set_delay(0.35)
	tween.parallel().tween_property(word_jumper, "scale", Vector2(1.3, 0.7), 0.2)
	tween.parallel().tween_property(word_jumper, "scale", Vector2.ONE, 0.5).set_delay(0.2)
	
	await tween.finished
	
	if lines.size() >= 2 and current_index + 1 < subtitle_list.size():
		await _transition_to_next_line()
	else:
		await _fall_down()

func _transition_to_next_line() -> void:
	var next_line_x = markers[0].position.x - (lines[1].size.x / 2)
	var transition_duration = lines[1].start_time - lines[0].end_time
	
	var down_tween := create_tween()
	down_tween.tween_method(
		func(t: float):
			word_jumper.global_position.y = lerp(
				word_jumper.global_position.y, 
				float(get_viewport().size.y + 50), 
				t
			),
		0.0, 1.0, transition_duration * 0.3
	).set_ease(Tween.EASE_IN)
	
	var move_tween := create_tween()
	move_tween.tween_method(
		func(t: float):
			word_jumper.global_position.x = lerp(
				word_jumper.global_position.x, 
				next_line_x - 100, 
				t
			),
		0.0, 1.0, transition_duration * 0.4
	).set_ease(Tween.EASE_IN_OUT).set_delay(transition_duration * 0.3)
	
	await move_tween.finished
	
	var up_tween := create_tween()
	up_tween.tween_method(
		func(t: float):
			word_jumper.global_position.y = lerp(
				word_jumper.global_position.y, 
				markers[0].position.y - 50, 
				t
			),
		0.0, 1.0, transition_duration * 0.3
	).set_ease(Tween.EASE_OUT)
	
	await up_tween.finished


func _fall_down() -> void:
	var screen_bottom := get_viewport().get_visible_rect().size.y + 100
	var fall_duration := 0.8
	
	var tween := create_tween()
	tween.tween_method(
		func(t: float):
			word_jumper.global_position.y = lerp(
				word_jumper.global_position.y, 
				screen_bottom, 
				t
			),
		0.0, 1.0, fall_duration
	).set_ease(Tween.EASE_IN)
	
	await tween.finished


func resume() -> void:
	is_playing = true
func pause() -> void:
	is_playing = false
func stop() -> void:
	is_playing = false
	current_time = 0.0
	current_index = 0
	for line in lines:
		line.queue_free()
	lines.clear()
