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
