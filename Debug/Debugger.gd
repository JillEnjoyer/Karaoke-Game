extends Node

class_name Logger

const MAX_LINES: int = 1000
const LOG_LEVELS := {
	"DEBUG": 0,
	"INFO": 1,
	"WARNING": 2,
	"ERROR": 3,
	"EXCEPTION": 4
}

var debugger_active: bool = true
var log_to_file: bool = true
var log_file_path: String = "logs/log"
var msg_struct: String = "{0} | {1} | {2}->{3}: {4}"
var current_log_level: int = LOG_LEVELS["DEBUG"]
var log_buffer: Array = []
var current_index: int = 0

func _init():
	# Инициализация лог-файла с текущей датой
	if log_to_file:
		var datetime = get_datetime()
		var date_string = "{year}-{month}-{day}".format({"year": datetime.year, "month": datetime.month, "day": datetime.day})
		log_file_path = "{file_path}_{date_string}.log".format({"file_path": log_file_path, "date_string": date_string})
		log_buffer.resize(MAX_LINES)
		for i in range(MAX_LINES):
			log_buffer[i] = ""


func logger(level: String, file_name: String, method_name: String, message: String) -> void:
	if LOG_LEVELS.get(level, -1) < current_log_level:
		return
	
	var timestamp = get_timestamp()
	var formatted_message = msg_struct.format({
		"0": timestamp,
		"1": level,
		"2": file_name,
		"3": method_name,
		"4": message
	})

	# Вывод в консоль
	if debugger_active:
		print(formatted_message)

	# Запись в буфер
	log_buffer[current_index] = formatted_message
	current_index = (current_index + 1) % MAX_LINES

	# Запись в файл
	if log_to_file:
		write_to_file(formatted_message)


func debug(file_name: String, method_name: String, message: String) -> void:
	logger("DEBUG", file_name, method_name, message)

func info(file_name: String, method_name: String, message: String) -> void:
	logger("INFO", file_name, method_name, message)

func warning(file_name: String, method_name: String, message: String) -> void:
	logger("WARNING", file_name, method_name, message)

func error(file_name: String, method_name: String, message: String) -> void:
	logger("ERROR", file_name, method_name, message)

func exception(file_name: String, method_name: String, message: String) -> void:
	logger("EXCEPTION", file_name, method_name, message)


func write_to_file(message: String) -> void:
	var file = FileAccess.open(log_file_path, FileAccess.WRITE_READ)
	if file:
		file.store_line(message)
		file.close()
	else:
		print("Failed to write to log file: {}".format(log_file_path))

func get_timestamp() -> String:
	var datetime = get_datetime()
	return "{year}-{month}-{day} {hour}:{minute}:{second}".format({
		"year": datetime.year, "month": datetime.month, "day": datetime.day,
		"hour": datetime.hour, "minute": datetime.minute, "second": datetime.second
	})

func get_datetime() -> Dictionary:
	# Получает текущую дату и время как словарь
	return Time.get_datetime_dict_from_system()
