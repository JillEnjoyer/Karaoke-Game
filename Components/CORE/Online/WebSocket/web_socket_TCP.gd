extends Node

var ws_server := WebSocketMultiplayerPeer.new()
var http_server := TCPServer.new()
var clients := {}  # Connected client dictionary
var html_page := "res://WebSocket/site.html"

@onready var test_viewport = UIManager.default_parent

var buffer : float = 0.016  # Frame send frequency (in seconds) - Depends on user preferences. Basic is from 14 to 30 fps. More is not recommended.
var dtime := 0.0  # Delta time from previously sent frame

func _ready():
	var err = ws_server.create_server(8082)
	if err != OK:
		Debugger.error("Error with WebSocket-server startup: " + str(err))
		return

	ws_server.peer_connected.connect(_on_client_connected)
	ws_server.peer_disconnected.connect(_on_client_disconnected)

	err = http_server.listen(8083)
	if err != OK:
		Debugger.error("Error with HTTP-server startup: " + str(err))
		return

	set_process(true)

func _process(delta):
	ws_server.poll()  # Updating WebSocket
	handle_http_connections()

	dtime += delta
	if dtime >= buffer:
		dtime -= buffer
		if not clients.is_empty():
			send_frame_to_clients()


func handle_http_connections():
	if http_server.is_connection_available():
		var client = http_server.take_connection()
		var html_data = load_file(html_page)

		if html_data.is_empty():
			Debugger.info("HTML-file is empty or is not found!")
			pass
		else:
			Debugger.info("HTML-file uploaded, size: " + str(html_data.size()))
			pass
		
		var response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: %d\r\n\r\n%s" % [
			html_data.size(), html_data.get_string_from_utf8()
		]

		Debugger.info("Sending HTML to the client...")
		client.put_data(response.to_utf8_buffer())
		await get_tree().create_timer(0.1).timeout
		client.disconnect_from_host()


func _on_client_connected(peer_id):
	Debugger.info("Current clients: " + str(clients.keys()))
	clients[peer_id] = {"last_response": Time.get_ticks_msec()}



func _on_client_disconnected(peer_id):
	Debugger.info("Client disconnected: " + str(peer_id))
	clients.erase(peer_id)


func send_frame_to_clients():
	var image = test_viewport.get_texture().get_image()
	#var png_data: PackedByteArray
	var jpg_data: PackedByteArray
	#var png_data_string: String
	if image:
		Debugger.info("✅ Image captured successfully")
		image.resize(854, 480)
		#image.convert(Image.FORMAT_RGB8)
		
		#png_data = image.save_png_to_buffer()
		jpg_data = image.save_jpg_to_buffer(0.5)
		#png_data_string = Marshalls.raw_to_base64(png_data)
		if jpg_data.size() > 0:
			Debugger.info("PNG data created successfully, size: " + str(jpg_data.size()) + " bytes")
			pass
		else:
			Debugger.error("Error: PNG data is empty")
			pass
	else:
		Debugger.error("Error: Failed to capture image from ViewPort")
	
	Debugger.info(str(clients))
	for peer_id in clients:
		ws_server.get_peer(peer_id).put_packet(jpg_data)  # Sending base64 line
		#ws_server.get_peer(peer_id).send_text(png_data_string)
	#check_client_activity()

func check_client_activity():
	var current_time = Time.get_ticks_msec()
	for peer_id in clients:
		if current_time - clients[peer_id]["last_response"] > 5000:
			Debugger.info("Client is not responding, disconnecting: " + str(peer_id))
			ws_server.disconnect_peer(peer_id)
			clients.erase(peer_id)


func load_file(path: String) -> PackedByteArray:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_buffer(file.get_length())
	return PackedByteArray()
