extends Node

var ws_server := WebSocketMultiplayerPeer.new()  # WebSocket сервер
var http_server := TCPServer.new()  # HTTP сервер
var clients := {}  # Словарь для хранения подключённых клиентов
var html_page := "res://WebSocket/site.html"  # HTML-файл

@onready var test_viewport = get_node("/root/ViewportBase/SubViewportContainer/SubViewport")

var buffer : float = 0.016  # Интервал отправки кадров (в секундах)
var dtime := 0.0  # Накопленное время с последней отправки кадра

func _ready():
	# Запуск WebSocket сервера
	var err = ws_server.create_server(8082)
	if err != OK:
		print("❌ Ошибка запуска WebSocket-сервера: ", err)
	else:
		#print("✅ WebSocket запущен на ws://localhost:8082")
		pass

	# Подключаем сигналы для обработки подключений и отключений клиентов
	ws_server.peer_connected.connect(_on_client_connected)
	ws_server.peer_disconnected.connect(_on_client_disconnected)

	# Запуск HTTP сервера
	err = http_server.listen(8083)
	if err != OK:
		print("❌ Ошибка запуска HTTP-сервера: ", err)
	else:
		#print("✅ HTTP сервер запущен на http://localhost:8083")
		pass
	set_process(true)

func _process(delta):
	ws_server.poll()  # Обновление WebSocket
	#print("📡 Статус WebSocket:", ws_server.get_connection_status())
	handle_http_connections()  # Обрабатываем HTTP

	dtime += delta
	if dtime >= buffer:
		dtime -= buffer
		if clients.is_empty():
			pass
			#print("⚠️ Нет активных клиентов, пропускаем отправку кадра")
		else:
			send_frame_to_clients()  # Отправляем кадр клиентам


func handle_http_connections():
	if http_server.is_connection_available():
		#print("connection avaliable")
		var client = http_server.take_connection()
		var html_data = load_file(html_page)

		if html_data.is_empty():
			print("⚠️ HTML-файл пуст или не найден!")
			pass
		else:
			print("✅ HTML-файл загружен, размер:", html_data.size())
			pass
		
		var response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: %d\r\n\r\n%s" % [
			html_data.size(), html_data.get_string_from_utf8()
		]

		print("📤 Отправляем HTML клиенту...")
		client.put_data(response.to_utf8_buffer())
		await get_tree().create_timer(0.1).timeout
		client.disconnect_from_host()


func _on_client_connected(peer_id):
	#print("🔗 Клиент подключился:", peer_id)
	print("📋 Текущие клиенты:", clients.keys())  # Проверяем список клиентов
	clients[peer_id] = {"last_response": Time.get_ticks_msec()}



func _on_client_disconnected(peer_id):
	print("❌ Клиент отключился:", peer_id)
	clients.erase(peer_id)  # Удаляем клиента из списка


func send_frame_to_clients():
	var image = test_viewport.get_texture().get_image()
	#var png_data: PackedByteArray
	var jpg_data: PackedByteArray
	#var png_data_string: String
	if image:
		print("✅ Изображение успешно захвачено")
		image.resize(854, 480)
		#image.convert(Image.FORMAT_RGB8)
		
		#png_data = image.save_png_to_buffer()
		jpg_data = image.save_jpg_to_buffer(0.5)
		#png_data_string = Marshalls.raw_to_base64(png_data)
		if jpg_data.size() > 0:
			print("✅ PNG данные успешно созданы, размер:", jpg_data.size(), "bytes")
			pass
		else:
			print("❌ Ошибка: PNG данные пусты")
			pass
	else:
		print("❌ Ошибка: не удалось захватить изображение из ViewPort")
	
	print(clients)
	for peer_id in clients:
		ws_server.get_peer(peer_id).put_packet(jpg_data)  # Отправка строки base64
		#ws_server.get_peer(peer_id).send_text(png_data_string)  # Отправка строки base64

	#check_client_activity()

func check_client_activity():
	var current_time = Time.get_ticks_msec()
	for peer_id in clients:
		if current_time - clients[peer_id]["last_response"] > 5000:  # 5 секунд
			print("❌ Клиент не отвечает, отключаем:", peer_id)
			ws_server.disconnect_peer(peer_id)
			clients.erase(peer_id)


func load_file(path: String) -> PackedByteArray:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_buffer(file.get_length())
	return PackedByteArray()
