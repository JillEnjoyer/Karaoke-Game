# Can be possibly a singleton with different values that can be converter
extends Node
class_name ValueConverter


## TIMELINE CONVERSIONS ##

static var timestamp = 5.0 # seconds per frame - can be changed by resize
static var px_to_sec: float = (70.0 * 16.0 / 9.0) / timestamp # should be dinamic to timestamp change

static func change_timestamp(new_ts: float = 5.0) -> void:
	timestamp = new_ts
	px_to_sec = (70.0 * 16.0 / 9.0) / timestamp

static func time_to_px(t: float) -> float:
	return t * px_to_sec
static func px_to_time(px: float) -> float:
	return px / px_to_sec


## TIME CONVERSIONS ##

static func time_to_display_string(time: float) -> String:
	var minutes = int(time) / 60.0
	var seconds = int(time) % 60
	return "%02d:%02d" % [minutes, seconds]


static func logical_to_physical(normalized_jumpers: Array, time_logical: float) -> float:
	for segment in normalized_jumpers:
		if time_logical >= segment["logical_start"] and time_logical <= segment["logical_end"]:
			var offset = time_logical - segment["logical_start"]
			return segment["physical_start"] + offset
	return 0.0 #physical_time
static func physical_to_logical(normalized_jumpers: Array, time_physical: float) -> float:
	for segment in normalized_jumpers:
		if time_physical >= segment["physical_start"] and time_physical <= segment["physical_end"]:
			var offset = time_physical - segment["physical_start"]
			return segment["logical_start"] + offset
	return 0.0 #logical_time