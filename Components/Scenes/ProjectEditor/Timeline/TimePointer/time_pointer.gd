# time_pointer.gd
extends Control

signal pointer_moved(new_time)
signal move_timeline(delta_move_in_px)

@onready var drag_btn = $DragBtn
@onready var timeline_panel = $"../../TimelinePanel"

var is_dragging := false
var is_moving := false
var drag_start_mouse_x := 0.0
var drag_start_position_x := 0.0

## its percent + percent of timeline scroll position and px to sec conversion will give us exact pointer time
const trigger_zone_in_percent := 0.5 # from 0.0 to 1.0 (not used for edge math here)
var pointer_position_in_percent := 0.0 # 0.0 - 1.0
var pointer_time = 0.0 # in seconds

var pointer_position_in_px := 0.0
var pointer_position_in_sec := 0.0

# Tunables
const EDGE_ZONE := 0.02 # 5% on each side = zone where autoscroll applies
const BASE_SCROLL_SPEED := 600.0 # px per second at strength == 1
const NUDGE_FACTOR := 1.0 # how strongly pointer itself is nudged away from edge


func _ready():
	drag_btn.connect("gui_input", _on_drag_btn_gui_input)


## Strength of automatic moving of pointer when it is near the edges of timeline panel.
## position_in_percent expected in 0..1
## returns 0..1 where 1 => strongest
func get_moving_strength_multiplier(position_in_percent: float) -> float:
	var t: float = 0.0

	# Edge zones
	if position_in_percent <= EDGE_ZONE:
		t = clamp(position_in_percent / EDGE_ZONE, 0.3, 1.0) # 0 @ edge, 1 @ zone boundary
	elif position_in_percent >= 1.0 - EDGE_ZONE:
		t = clamp((1.0 - position_in_percent) / EDGE_ZONE, 0.3, 1.0)
	else:
		return 0.0

	# Settings for your curve
	var peak = 0.15
	var sigma = 0.12
	var gaussian = exp(-pow(t - peak, 2) / (2.0 * sigma * sigma))

	# When t approaches 0 (the very edge), the result will approach 1.0
	var linear_exit = 1.0 - (t / 0.33) ## last third

	var result = max(gaussian, clamp(linear_exit, 0.05, 1.0))

	return clamp(result, 0.0, 1.0)


func get_moving_strength_custom(position_in_percent: float) -> float:
	if position_in_percent <= EDGE_ZONE:
		return 1.0
	elif position_in_percent < 1.0 - EDGE_ZONE:
		
		var t = (position_in_percent - EDGE_ZONE) / (1.0 - EDGE_ZONE - EDGE_ZONE)
		return (100.0 - 35.0 * t) / 100.0
	elif position_in_percent > 1.0 - EDGE_ZONE:
		var t = (position_in_percent - (1.0 - EDGE_ZONE)) / (EDGE_ZONE)
		return (65.0 * (1.0 - t)) / 100.0
	return 0.0


func _on_drag_btn_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_mouse_x = get_global_mouse_position().x
			drag_start_position_x = position.x + size.x / 2
		else:
			is_dragging = false
			if not is_moving:
				_move_pointer(true)

	elif is_dragging and event is InputEventMouseMotion:
		var min_x = 0.0
		var max_x = timeline_panel.size.x
		
		var mouse_delta_x = get_global_mouse_position().x - drag_start_mouse_x
		var new_x = drag_start_position_x + mouse_delta_x

		# Clamp pointer position (center coordinate)
		var center_x = clamp(new_x, min_x, max_x)
		position.x = center_x - size.x / 2
		
		# percent in 0..1
		pointer_position_in_percent = center_x / timeline_panel.size.x
		Debugger.debug("Pointer Position Percent: " + str(pointer_position_in_percent))
		
		pointer_position_in_px = center_x
		pointer_position_in_sec = ValueConverter.px_to_time(pointer_position_in_px)
		
		Debugger.debug("Pointer Position: " + str(pointer_position_in_px))

		# start movement coroutine if not running
		if not is_moving:
			_move_pointer(false)


func signal_move_timeline(strength: float) -> void:
	emit_signal("move_timeline", strength)


func _move_pointer(repeat: bool = false) -> void:
	if is_moving:
		return
	is_moving = true
	var min_interval := 0.008 # ~120 Hz
	var last_time := Time.get_ticks_msec() / 1000.0
	while true:
		if get_tree() == null:
			# With certain chance while scene being freed, this code may still run one more time and cause errors
			break
		await get_tree().process_frame
		var now := Time.get_ticks_msec() / 1000.0
		var dt := now - last_time
		if dt < min_interval:
			continue
		last_time = now

		# current pointer center percent
		var center_x = position.x + size.x / 2
		pointer_position_in_percent = center_x / timeline_panel.size.x
		pointer_position_in_px = center_x

		var moving_strength = 0.0#get_moving_strength_multiplier(pointer_position_in_percent)
		#if moving_strength <= 0.0:
		#	break

		var delta_px = 5.0#moving_strength * BASE_SCROLL_SPEED * dt

		if is_dragging:
			if pointer_position_in_percent <= 0.01:
				#position.x = clamp(position.x + delta_px * NUDGE_FACTOR, 0.0 - size.x / 2, timeline_panel.size.x - size.x / 2)
				_move_timeline(-round(delta_px))
			elif pointer_position_in_percent >= 0.99:
				#position.x = clamp(position.x - delta_px * NUDGE_FACTOR, 0.0 - size.x / 2, timeline_panel.size.x - size.x / 2)
				_move_timeline(round(delta_px))
		else:
			if pointer_position_in_percent <= 0.01:
				position.x = clamp(position.x + delta_px * NUDGE_FACTOR, 0.0 - size.x / 2, timeline_panel.size.x - size.x / 2)
				_move_timeline(-round(delta_px))
			elif pointer_position_in_percent >= 0.99:
				position.x = clamp(position.x - delta_px * NUDGE_FACTOR, 0.0 - size.x / 2, timeline_panel.size.x - size.x / 2)
				_move_timeline(round(delta_px))

		center_x = position.x + size.x / 2
		pointer_position_in_percent = center_x / timeline_panel.size.x
		pointer_position_in_px = center_x
		pointer_position_in_sec = ValueConverter.px_to_time(pointer_position_in_px)
		emit_signal("pointer_moved", pointer_position_in_sec)

		if not repeat:
			break

	is_moving = false


func _move_timeline(delta: int) -> void:
	emit_signal("move_timeline", delta)
