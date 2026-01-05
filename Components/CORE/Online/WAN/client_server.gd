extends Node
class_name ClientServer

var nat_manager = load("res://Components/Core/Online/WAN/NatManager.gd").new()

var potential_tcp_ports = [8676, 8677, 8680, 8681]
var potential_udp_ports = [8678, 8679, 8682, 8683]

var tcp_server: WebSocketMultiplayerPeer
var tcp_client: WebSocketMultiplayerPeer # me as a client
var udp_server := PacketPeerUDP.new()
var udp_client : Dictionary = {} # is that needed?

var clients : Dictionary = {}


func _ready():
	var tcp_port = pick_free_port(potential_tcp_ports)
	var udp_port = pick_free_port(potential_udp_ports)

	nat_manager.MapPorts(tcp_port, udp_port)

	start_tcp_server(tcp_port)
	start_udp_server(udp_port)

	Debugger.info("Server started at TCP:" + str(tcp_port) + " UDP:" + str(udp_port))


func _on_client_connected(id):
	clients[id] = {"name": "Unknown", "score": 0}
	Debugger.info("Client connected: ", id)


func _on_client_disconnected(id):
	clients.erase(id)
	Debugger.info("Client disconnected: ", id)


func _on_data_received(client_id, data):
	var message = JSON.parse_string(data.get_string_from_utf8())
	if typeof(message) != TYPE_DICTIONARY:
		Debugger.error("Error parsing JSON: ", data)
		return

	match message.get("type", ""):
		"set_name":
			clients[client_id].name = message.get("name", "Unknown")
		"update_score":
			clients[client_id].score += message.get("points", 0)
		_:
			Debugger.warning("Unknown message type: ", message.get("type", ""))

	broadcast_client_data()


func broadcast_client_data():
	var data = []
	for client_id in clients.keys():
		data.append({"id": client_id, "name": clients[client_id].name, "score": clients[client_id].score})
	#server.broadcast(JSON.stringify(data))


func pick_free_port(port_array: Array) -> int:
	for port in port_array:
		var tcp_server = TCPServer.new()
		if tcp_server.listen(port) == OK:
			tcp_server.stop()
			return port
	var random_port = randi() % 50000 + 15000
	return random_port


func start_tcp_server(port: int):
	tcp_server = WebSocketMultiplayerPeer.new()
	var err = tcp_server.create_server(port)
	if err != OK:
		Debugger.error("Can't start TCP server on port %d" % port)
		return
	multiplayer.multiplayer_peer = tcp_server
	tcp_server.peer_connected.connect(_on_client_connected)
	tcp_server.peer_disconnected.connect(_on_client_disconnected)
	#tcp_server.data_received.connect(_on_tcp_data)
	#Debugger.info("TCP server started at port: ", port)


func start_udp_server(port: int):
	var err = udp_server.listen(port)
	if err != OK:
		Debugger.error("Failed to start UDP server")
		return
	Debugger.info("UDP server started on port %d" % port)


func connect_to_server(ip: String, port: int):
	tcp_client = WebSocketMultiplayerPeer.new()
	var err = tcp_client.create_client("ws://%s:%d" % [ip, port])
	if err != OK:
		Debugger.error("Failed to connect to TCP server")
		return
	multiplayer.multiplayer_peer = tcp_client
	#tcp_client.data_received.connect(_on_tcp_data)
	Debugger.info("TCP client connected")


func _process(_delta):
	if udp_server and udp_server.is_listening():
		while udp_server.get_available_packet_count() > 0:
			var packet = udp_server.get_packet()
			var ip = udp_server.get_packet_address()
			var port = udp_server.get_packet_port()

			## If client not registered — fix it
			#if not udp_clients.has(ip):
				#udp_clients[ip] = port
				#Debugger.info("UDP client registered: %s:%d" % [ip, port])

			#handle_udp_packet(ip, port, packet)
