extends Control

@onready var file_dialog: FileDialog = $FileDialog
@onready var status_label: Label = $StatusLabel

var command_peer := StreamPeerTCP.new()
var response_peer := StreamPeerTCP.new()
var worker_ready := false

var selected_audio_path: String = ""
var target_dirs := {
	"vocals": "W:/AudioSplitter",
	"drums": "W:/AudioSplitter",
	"bass": "W:/AudioSplitter",
	"other": "W:/AudioSplitter"
}

func _ready() -> void:
	await get_tree().create_timer(5).timeout
	VocatoolWatchdog.tool_ready.connect(_on_splitter_ready)
	launch_worker()

func launch_worker():
	VocatoolWatchdog.request_tool("audio_splitter")

func _on_splitter_ready(tool_name, in_p, out_p):
	if tool_name == "audio_splitter":
		command_peer.connect_to_host("127.0.0.1", int(in_p))
		response_peer.connect_to_host("127.0.0.1", int(out_p))
		worker_ready = true
		status_label.text = "AI ready"


func _on_select_audio_btn_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_ANY
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.mp3, *.wav, *.flac ; Audio Files"]
	file_dialog.title = "Choose song (Seishun Towa)"
	file_dialog.show()

	if file_dialog.file_selected.is_connected(_on_audio_selected):
		file_dialog.file_selected.disconnect(_on_audio_selected)
	file_dialog.file_selected.connect(_on_audio_selected)

func _on_audio_selected(path: String):
	selected_audio_path = path
	status_label.text = "File chosen: " + path.get_file()
	start_ai_processing()

func _on_select_folder_pressed(type: String):
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.title = "Folder for: " + type
	file_dialog.show()
	
	if file_dialog.dir_selected.is_connected(_on_folder_selected):
		file_dialog.dir_selected.disconnect(_on_folder_selected)
	
	file_dialog.dir_selected.connect(_on_folder_selected.bind(type))

func _on_folder_selected(path: String, type: String):
	target_dirs[type] = path
	status_label.text = "Folder " + type + " Set."


func start_ai_processing():
	if not worker_ready:
		status_label.text = "Error: Worker is not ready!"
		return
	
	if selected_audio_path == "" or target_dirs["vocals"] == "":
		status_label.text = "Error: Choose file and folders!"
		return

	var cmd = {
		"action": "process",
		"path": selected_audio_path,
		"mode": "2stems",
		"target_dirs": {
			"vocals": target_dirs["vocals"],
			"drums": target_dirs["drums"],
			"bass": target_dirs["bass"],
			"other": target_dirs["other"]
		},
		"output_names": {
			"vocals": "all",
			"drums": "drums",
			"bass": "bass",
			"other": "other"
		}
	}
	
	send_command(cmd)
	status_label.text = "Sent for processing..."

func send_command(cmd_dict: Dictionary) -> void:
	if command_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_str = JSON.stringify(cmd_dict) + "\n"
		command_peer.put_data(json_str.to_utf8_buffer())
	else:
		status_label.text = "Connection error!"

func _process(_delta):
	if worker_ready:
		command_peer.poll()
		response_peer.poll()
		
		if response_peer.get_available_bytes() > 0:
			var data = response_peer.get_data(response_peer.get_available_bytes())
			if data[0] == OK:
				_handle_response(data[1].get_string_from_utf8())

func _handle_response(json_str: String):
	var response = JSON.parse_string(json_str)
	if response:
		match response.get("status"):
			"processing":
				status_label.text = "Working: " + response.get("msg", "")
			"completed":
				status_label.text = "Ready! Files processed."
			"error":
				status_label.text = "AI error: " + response.get("msg", "")
			"busy":
				status_label.text = "Process is busy..."
