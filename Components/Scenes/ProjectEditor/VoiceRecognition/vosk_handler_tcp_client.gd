extends Node

# Изменили названия сигналов под Whisper
signal whisper_result_ready(result_data: Array)
signal download_progress_updated(percent: float, text: String)
signal status_message(msg: String)

var command_peer := StreamPeerTCP.new()
var response_peer := StreamPeerTCP.new()
var stream_buffer := PackedByteArray()
var worker_ready := false

func _ready() -> void:
	pass

# FFmpeg больше не нужен, но если архитектура требует аргумента, передаем пустышку
func launch_worker(dummy_ffmpeg_path: String = ""):
	VocatoolWatchdog.request_tool("whisper_handler", [dummy_ffmpeg_path])

func _on_tool_ready(tool_name, in_p, out_p):
	if tool_name == "whisper_handler":
		command_peer.connect_to_host("127.0.0.1", int(in_p))
		response_peer.connect_to_host("127.0.0.1", int(out_p))
		worker_ready = true
		Debugger.debug("Connected to Whisper worker on ports: " + str(in_p) + ", " + str(out_p))

# ТЕПЕРЬ ПРИНИМАЕМ 3 АРГУМЕНТА!
func process_audio_file(audio_path: String, model_dir: String, model_name: String):
	Debugger.info("ПЫТАЮСЬ ОТПРАВИТЬ ПУТЬ: " + audio_path) # <--- ДОБАВЬ ЭТО
	var cmd = {
		"action": "transcribe",
		"path": audio_path,
		"model_dir": model_dir,
		"model_name": model_name
	}
	send_command(cmd)

func _process(_delta: float) -> void:
	if not worker_ready: 
		return

	command_peer.poll()
	response_peer.poll()

	var status = response_peer.get_status()
	
	if status == StreamPeerTCP.STATUS_CONNECTED:
		var avail = response_peer.get_available_bytes()
		if avail > 0:
			var data = response_peer.get_data(avail)
			if data[0] == OK:
				stream_buffer.append_array(data[1])
				process_stream()
	elif status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
		worker_ready = false
		Debugger.error("Connection to Whisper worker lost... Status: " + str(status))

func process_stream() -> void:
	var loops = 0
	while stream_buffer.size() > 0 and loops < 5:
		loops += 1
		
		var newline_idx = stream_buffer.find(10)
		if newline_idx == -1: break
		
		var json_bytes = stream_buffer.slice(0, newline_idx)
		stream_buffer = stream_buffer.slice(newline_idx + 1)
		
		var json_str = json_bytes.get_string_from_utf8()
		var data = JSON.parse_string(json_str)
		
		if data == null: continue
		
		var status = data.get("status", "")
		
		# ОБРАБОТКА НОВЫХ СТАТУСОВ СКАЧИВАНИЯ
		if status == "downloading":
			var pct = data.get("percent", 0.0)
			var txt = data.get("progress_text", "")
			download_progress_updated.emit(pct, txt)
			# Не спамим в консоль каждый процент, чисто отдаем в UI
			
		elif status == "info" or status == "download_completed" or status == "processing":
			var msg = data.get("msg", status)
			status_message.emit(msg)
			Debugger.info("[Whisper] " + msg)
			
		elif status == "completed":
			var result_array = data.get("full_data", [])
			whisper_result_ready.emit(result_array)
			
		elif status == "error":
			Debugger.error("[Whisper Error] " + data.get("msg", "Unknown error"))

func send_command(cmd_dict: Dictionary) -> void:
	if command_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_str = JSON.stringify(cmd_dict) + "\n"
		command_peer.put_data(json_str.to_utf8_buffer())
	else:
		Debugger.error("Whisper worker is not connected!")

func _exit_tree() -> void:
	VocatoolWatchdog.terminate_tool("whisper_handler")
