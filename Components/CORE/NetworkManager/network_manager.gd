extends Node

# Сигналы для высокоуровневых менеджеров (например, для VoiceManager)
signal packet_received(sender_id: int, data: PackedByteArray, timestamp: int)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

enum NetType { ENET, STEAM }
var current_type: NetType = NetType.ENET

func _ready():
	# Коннектим базовые сигналы Godot к нашим кастомным
	multiplayer.peer_connected.connect(func(id): peer_connected.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_disconnected.emit(id))

# ==========================================
# 1. УПРАВЛЕНИЕ ПОДКЛЮЧЕНИЕМ (ШЛЮЗЫ)
# ==========================================

# Запуск в режиме IP (ENet)
func start_enet_host(port: int, max_players: int) -> Error:
	current_type = NetType.ENET
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, max_players)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err

func start_enet_client(ip: String, port: int) -> Error:
	current_type = NetType.ENET
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err

# Запуск в режиме Steam (заглушка, если используешь GodotSteam)
func start_steam_lobby(steam_peer_instance: MultiplayerPeer) -> void:
	current_type = NetType.STEAM
	multiplayer.multiplayer_peer = steam_peer_instance

# ==========================================
# 2. НИЗКОУРОВНЕВАЯ ОТПРАВКА И ПРИЕМ (Универсальная)
# ==========================================

# Отправить пакет вообще ВСЕМ (вызывается на верхнем уровне)
func send_packet_to_all(data: PackedByteArray):
	var my_timestamp = Time.get_ticks_msec()
	_receive_rpc_packet.rpc(data, my_timestamp)

# Отправить пакет КОНКРЕТНОМУ игроку (понадобится для ЛС или тет-а-тет механик)
func send_packet_to_peer(peer_id: int, data: PackedByteArray):
	var my_timestamp = Time.get_ticks_msec()
	_receive_rpc_packet.rpc_id(peer_id, data, my_timestamp)

# Основной RPC-приемник. Автоматически срабатывает на удаленных компах.
# "unreliable_ordered" идеален для голоса и динамики, канал 1 разделяет трафик.
@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _receive_rpc_packet(data: PackedByteArray, timestamp: int):
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Выплевываем данные в верхние менеджеры (VoiceManager ловит и играет звук)
	packet_received.emit(sender_id, data, timestamp)
