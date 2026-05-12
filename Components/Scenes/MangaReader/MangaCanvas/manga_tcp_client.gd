## manga_tcp_client.gd ## all related to communication
extends Node

#signal connected_to_worker
#signal disconnected_from_worker
signal file_loaded(page_count: int)
signal page_downloaded(image_bytes: PackedByteArray, meta: Dictionary)
signal clear_page_buffer(new_page: int)

var command_peer := StreamPeerTCP.new()
var response_peer := StreamPeerTCP.new()
var stream_buffer := PackedByteArray()
var is_waiting_for_image := false
var expected_image_size := 0
var current_page_meta := {}
var worker_ready := false


func _ready() -> void:
	VocatoolWatchdog.tool_ready.connect(_on_manga_reader_ready)
	launch_worker()


func _on_manga_reader_ready(tool_name, in_p, out_p):
	if tool_name == "manga_reader":
		command_peer.connect_to_host("127.0.0.1", int(in_p))
		response_peer.connect_to_host("127.0.0.1", int(out_p))

		worker_ready = true

		Debugger.debug("Connected to worker on ports: " + str(in_p) + ", " + str(out_p))


func load_manga_file(file_path: String):
	var cmd = {
		"action": "load_file",
		"path": file_path
	}
	Debugger.info("load_file: {" + file_path + "} sent...")
	send_command(cmd)
	clear_page_buffer.emit(0)
	get_manga_page(0)


func get_manga_page(page: int):
	var cmd = {
		"action": "get_page",
		"page": page
	}
	Debugger.info("get_page: {" + str(page) + "} sent...")
	send_command(cmd)


func launch_worker():
	## Ask to kill existing worker from hub if it still alive
	VocatoolWatchdog.request_tool("manga_reader")


func _process(_delta: float) -> void:
	if not worker_ready: 
		Debugger.warning("Worker is not ready, skipping...")
		await get_tree().create_timer(0.1).timeout
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
		Debugger.error("Connection to worker lost... Status: " + str(status))
		Debugger.info("Trying to restore connection in 1 second...")
		


func process_stream() -> void:
	var loops = 0
	while stream_buffer.size() > 0 and loops < 5:
		loops += 1
		
		if not is_waiting_for_image:
			var newline_idx = stream_buffer.find(10)
			if newline_idx == -1: break
			
			var json_bytes = stream_buffer.slice(0, newline_idx)
			stream_buffer = stream_buffer.slice(newline_idx + 1)
			
			var json_str = json_bytes.get_string_from_utf8()
			var data = JSON.parse_string(json_str)
			
			if data == null: continue
			
			var status = data.get("status", "")
			# Getting JSON-header
			Debugger.info("[Stream] JSON collected: " + str(data)) 
			
			if status == "ready":
				file_loaded.emit(int(data.get("pages", 0)))
			elif status == "page_data":
				current_page_meta = data
				expected_image_size = int(data.get("image_size", 0)) 
				is_waiting_for_image = true
				Debugger.info("[Stream] Waiting for image data: " + str(expected_image_size) + " bytes")
		else:
			if stream_buffer.size() >= expected_image_size:
				# Image collected completely
				Debugger.info("[Stream] Image packet received! Size in buffer: " + str(stream_buffer.size()) + " bytes")
				
				var image_bytes = stream_buffer.slice(0, expected_image_size)
				stream_buffer = stream_buffer.slice(expected_image_size)
				
				is_waiting_for_image = false
				page_downloaded.emit(image_bytes, current_page_meta)
			else:
				break


# For sending JSON
func send_command(cmd_dict: Dictionary) -> void:
	if command_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_str = JSON.stringify(cmd_dict) + "\n"
		command_peer.put_data(json_str.to_utf8_buffer())
	else:
		Debugger.error("MangaReader is not connected!")
