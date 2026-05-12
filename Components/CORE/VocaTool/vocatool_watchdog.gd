# vocatool_watchdog.gd
extends Node

# Signals for other game components
signal hub_connected
signal tool_ready(tool_name, in_port, out_port)

var hub_in_peer := StreamPeerTCP.new()
var hub_out_peer := StreamPeerTCP.new()
var hub_pid : int = -1
var retry_timer = 2.0
var is_hub_ready := false
var handshake_sent := false

# Hub ports
var hub_in_port : int = -1
var hub_out_port : int = -1


func _ready() -> void:
	launch_vocatool()
	await get_tree().create_timer(1.0).timeout
	connect_to_hub()


func launch_vocatool() -> void:
	var path_to_exe = ""
	
	if OS.has_feature("editor"):
		path_to_exe = "W:/Projects/Python/VocaTool/dist/Vocatool/Vocatool.exe"
		#path_to_exe = "X:/Projects/Godot/Karaoke/Python/VocaTool/dist/Vocatool/Vocatool.exe"
	else:
		# In export it will be in the same folder as exe
		path_to_exe = OS.get_executable_path().get_base_dir() + "/VocaTool/Vocatool.exe"
	
	var ports: Array = []
	while ports.is_empty():
		ports = get_free_ports()
		Debugger.debug("[Watchdog] Looking for free ports for Hub... Found: " + str(ports))

	hub_in_port = ports[0]
	hub_out_port = ports[1]

	if FileAccess.file_exists(path_to_exe):

		var args = ["/c", "start", "/wait", path_to_exe, str(hub_in_port), str(hub_out_port)]
		hub_pid = OS.create_process("cmd.exe", args)
		## TODO: Return after test
		#hub_pid = OS.create_process(path_to_exe, [str(hub_in_port), str(hub_out_port)])
		if not hub_pid == -1:
			Debugger.debug("[Watchdog] Hub started with PID: " + str(hub_pid))
			return
		push_error("[Watchdog] Failed to launch Hub process!")
	else:
		push_error("[Watchdog] Hub file not found at path: " + path_to_exe)


func get_free_ports() -> Array:
	var ports: Array = []
	for i in range(2):
		var temp_server = TCPServer.new()
		# Choosing port "0" — OS will assign a free port automatically
		if temp_server.listen(0) == OK:
			ports.append(temp_server.get_local_port())
			temp_server.stop()
		else:
			return []
	return ports


func connect_to_hub() -> void:
	var err_in = hub_in_peer.connect_to_host("127.0.0.1", int(hub_in_port))
	var err_out = hub_out_peer.connect_to_host("127.0.0.1", int(hub_out_port))

	if err_in == OK and err_out == OK:
		Debugger.info("[Watchdog] Attempt to connect to Hub...")


func _process(_delta: float) -> void:
	hub_in_peer.poll()
	hub_out_peer.poll()
	var status = hub_out_peer.get_status()
	
	if status == StreamPeerTCP.STATUS_CONNECTED:
		if not is_hub_ready and not handshake_sent:
			_send_handshake()
			handshake_sent = true
		
		_check_for_messages()
	
	elif status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
		if is_hub_ready:
			Debugger.error("[Watchdog] Connection with Hub lost!")
			is_hub_ready = false
	
	## maybe we can put some delay to avoid using much CPU on polling. - faster game works, faster it will check for messages.
	#await get_tree().create_timer(0.01).timeout

func _send_handshake() -> void:
	var msg = {
		"action": "handshake",
		"msg": "Hello Hub!",
		"pid": OS.get_process_id()
	}
	_send_to_hub(msg)


# Public method for new tools. Requests Hub to create new system process
func request_tool(tool_name: String, inputs: Array = []) -> void:
	var msg = {
		"action": "create_tool",
		"tool": tool_name,
		"process_inputs": inputs
	}
	_send_to_hub(msg)
	Debugger.debug("[Watchdog] Request to create tool: " + tool_name)


func terminate_tool(tool_name: String) -> void:
	var msg = {
		"action": "kill_worker",
		"worker_name": tool_name
	}
	_send_to_hub(msg)
	Debugger.debug("[Watchdog] Request to terminate tool: " + tool_name)


func _send_to_hub(data: Dictionary) -> void:
	var json_str = JSON.stringify(data) + "\n"
	hub_in_peer.put_data(json_str.to_utf8_buffer())


func _check_for_messages() -> void:
	var avail = hub_out_peer.get_available_bytes()
	if avail > 0:
		var data = hub_out_peer.get_string(avail)
		Debugger.debug("[Watchdog] Received raw data from Hub: " + data)

		# Hub may send multiple JSON messages in one batch, so we split by newlines and parse each separately
		var lines = data.split("\n")
		for line in lines:
			if line.is_empty(): continue
			
			var json = JSON.new()
			if json.parse(line) == OK:
				_handle_hub_response(json.get_data())
			else:
				Debugger.error("[Watchdog] Failed to parse JSON from Hub: " + line)


func _handle_hub_response(data: Dictionary) -> void:
	Debugger.debug("[Watchdog] Received message from Hub: " + str(data))
	var status = data.get("status")
	
	if status == "handshake_ok":
		is_hub_ready = true
		hub_connected.emit()
		Debugger.debug("[Watchdog] Hub says: " + data.get("msg", ""))

	elif status == "worker_created":
		# Hub sent us the ports for the new tool
		var tool_name = data.get("tool")

		var in_p = data.get("in_port", 9071)
		var out_p = data.get("out_port", 9072)
		
		Debugger.debug("[Watchdog] Tool " + tool_name + " is ready on ports: " + str(in_p) + " " + str(out_p))
		tool_ready.emit(tool_name, in_p, out_p)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		Debugger.info("Closing Godot. Sending termination command to Hub...")
		if is_hub_ready:
			_send_to_hub({"action": "terminate_all_and_exit"})
			OS.delay_msec(100) # this is bad practice as window may break visually, but this ensures that godot successfully kills hub before exiting itself
