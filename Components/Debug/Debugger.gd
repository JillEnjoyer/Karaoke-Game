extends Node

const MAX_LINES: int = 1000
const LOG_LEVELS := {
	"DEBUG": 0,
	"INFO": 1,
	"WARNING": 2,
	"ERROR": 3,
	"EXCEPTION": 4
}

const COLOR_MAP := {
	"DEBUG": "#55ff55",     # green
	"INFO": "#55ccff",      # blue
	"WARNING": "#ffaa00",   # orange
	"ERROR": "#ff4444",     # red
	"EXCEPTION": "#cc55ff", # purple
	"TSTAMP": "#7FFFD4",    # gray
	"FILEFUNC": "#DAA520"
}

var debugger_active: bool = true
var log_to_file: bool = false
var log_file_path: String = "logs/log"
var msg_struct: String = "[{0}] [{1}] [{2}->{3}]: {4}"
var current_log_level: int = LOG_LEVELS["DEBUG"]
var log_buffer: Array = []
var current_index: int = 0


func _init():
	log_buffer.resize(MAX_LINES)
	for i in range(MAX_LINES):
		log_buffer[i] = ""

	if log_to_file:
		var datetime = get_datetime()
		var date_string = "{year}-{month}-{day}".format({
			"year": datetime.year,
			"month": datetime.month,
			"day": datetime.day
		})
		log_file_path = "{file_path}_{date_string}.log".format({
			"file_path": log_file_path,
			"date_string": date_string
		})


func logger(level: String, file_name: String, method_name: String, message: String) -> void:
	if LOG_LEVELS.get(level, -1) < current_log_level:
		return

	var timestamp = get_timestamp()
	var raw_message := msg_struct.format({
		"0": timestamp,
		"1": level,
		"2": file_name,
		"3": method_name,
		"4": message
	})

	if debugger_active:
		var colored := format_bbcode(timestamp, level, file_name, method_name, message)
		print_rich(colored)

	log_buffer[current_index] = raw_message
	current_index = (current_index + 1) % MAX_LINES

	if log_to_file:
		write_to_file(raw_message)


func format_bbcode(timestamp: String, level: String, file_name: String, method_name: String, message: String) -> String:
	var level_color = COLOR_MAP.get(level, "#ffffff")
	var filefunc_color = COLOR_MAP["FILEFUNC"]
	var tstamp_color = COLOR_MAP["TSTAMP"]

	var level_text = "[color=%s][%s][/color]" % [level_color, level]
	var time_text = "[color=%s][%s][/color]" % [tstamp_color, timestamp]
	var filefunc_text = "[color=%s][%s->%s][/color]" % [filefunc_color, file_name, method_name]

	return "%s %s %s: %s" % [time_text, level_text, filefunc_text, message]


func write_to_file(message: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
	if file:
		file.store_line(message)
		file.close()
	else:
		print("Failed to write to log file: %s" % log_file_path)


func get_timestamp() -> String:
	var datetime = get_datetime()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]


func get_datetime() -> Dictionary:
	return Time.get_datetime_dict_from_system()


func log_auto(level: String, var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	var file_name: String = ""
	var method_name: String = ""
	var message: String = ""
	if var_two == "" or var_three == "":
		var stack := get_stack()
		if stack.size() > 2:
			var caller = stack[2]
			file_name = caller.source.get_file()
			method_name = caller.function
			message = var_one
	else:
		file_name = var_one
		method_name = var_two
		message = var_three
	logger(level, file_name, method_name, message)


func debug(var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	log_auto("DEBUG", var_one, var_two, var_three)
func info(var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	log_auto("INFO", var_one, var_two, var_three)
func warning(var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	log_auto("WARNING", var_one, var_two, var_three)
func error(var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	log_auto("ERROR", var_one, var_two, var_three)
func exception(var_one: String = "", var_two: String = "", var_three: String = "") -> void:
	log_auto("EXCEPTION", var_one, var_two, var_three)
