#password_generator.gd
extends Control

@onready var destination_line_edit: LineEdit = $VBoxContainer/DestinationHBox/DestinationLineEdit
@onready var password_line_edit: LineEdit = $VBoxContainer/PasswordHBox/PasswordLineEdit
@onready var pin_code_line_edit: LineEdit = $VBoxContainer/PinCodeHBox/PinCodeLineEdit
@onready var optional_line_edit: LineEdit = $VBoxContainer/OptionalHBox/OptionalLineEdit

@onready var result_line_edit: LineEdit = $VBoxContainer/ControlHBox/VBoxContainer/LineEdit
@onready var clear_button: Button = $VBoxContainer/ControlHBox/VBoxContainer/HBoxContainer/ClearBtn
@onready var generate_button: Button = $VBoxContainer/ControlHBox/VBoxContainer/HBoxContainer/GenerateBtn
@onready var clipboard_button: Button = $VBoxContainer/ControlHBox/VBoxContainer/HBoxContainer/ClipboardBtn

var command_peer := StreamPeerTCP.new() # (in_port)
var response_peer := StreamPeerTCP.new() # (out_port)

#var worker_peer := StreamPeerTCP.new()
#var client_peer := TCPServer.new()
var is_worker_ready := false
var avaiting_response := false


func _ready() -> void:
	# Subscribe to VocaTool callback signal
	VocatoolWatchdog.tool_ready.connect(_on_tool_ready)
	
	# Only then request the tool
	VocatoolWatchdog.request_tool("password_generator")
	
	# While tool is not avaliable, disable tool related button
	generate_button.disabled = true


func _on_tool_ready(tool_name: String, in_port: int, out_port: int) -> void:
	Debugger.debug("Received tool_ready signal for tool: " + tool_name + " with ports: " + str(in_port) + ", " + str(out_port))
	if tool_name == "password_generator":
		var err_in = command_peer.connect_to_host("127.0.0.1", in_port)
		var err_out = response_peer.connect_to_host("127.0.0.1", out_port)

		if err_in == OK and err_out == OK:
			is_worker_ready = true
			generate_button.disabled = false
			Debugger.info("Connected to PasswordGenerator worker!")


func _process(_delta: float) -> void:
	#if avaiting_response:
	if is_worker_ready:
		command_peer.poll()
		response_peer.poll()
		if response_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_check_worker_responses()


func _on_generate_btn_pressed() -> void:
	if not is_worker_ready: return
	
	var request = {
		"action": "generate_password",
		"inputs": {
			"resource": destination_line_edit.text,
			"personal_password": password_line_edit.text,
			"special_combination": pin_code_line_edit.text,
			"attempt_optional": int(optional_line_edit.text) if optional_line_edit.text.is_valid_int() else 0
		},
		"parameters": {
			"size": 16,
			"upper_symbols": true,
			"special_symbols": true
		}
	}
	
	var json_str = JSON.stringify(request) + "\n"
	command_peer.put_data(json_str.to_utf8_buffer())


func _check_worker_responses() -> void:
	var avail = response_peer.get_available_bytes()
	if avail > 0:
		var data = response_peer.get_string(avail)
		var lines = data.split("\n")
		for line in lines:
			if line.is_empty(): continue
			var json = JSON.new()
			if json.parse(line) == OK:
				_handle_worker_data(json.get_data())


func _handle_worker_data(data: Dictionary) -> void:
	if data.get("status") == "success":
		var password = data.get("data", {}).get("password", "")
		result_line_edit.text = password
	elif data.get("status") == "error":
		push_error("Worker error: " + data.get("msg", "Unknown error"))


func _on_clear_btn_pressed() -> void:
	destination_line_edit.clear()
	password_line_edit.clear()
	pin_code_line_edit.clear()
	optional_line_edit.clear()
	result_line_edit.clear()


func _on_clipboard_btn_pressed() -> void:
	if not result_line_edit.text.is_empty():
		DisplayServer.clipboard_set(result_line_edit.text)


func _on_exit_btn_pressed() -> void:
	UIManager.show_ui("TempDebugMenu")
	self.queue_free()
