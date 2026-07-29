extends Node

# Сигналы для UI
signal text_message_received(chat_id: String, sender_id: int, text: String)
signal user_talking(user_id: int, audio_data: PackedFloat32Array)

# Перечисление типов данных внутри нашего Vox-протокола
enum PacketType { TEXT, VOICE }

# Настройки голосового движка (OPUS / Кастомное ухудшение)
var audio_settings = {
	"bitrate": 32000,          # от 6000 до 510000 bps
	"sample_rate": 48000,      # 48kHz (стандарт), можно занизить до 8000 для эффекта рации
	"custom_degradation": 0.0  # Коэффициент порчи звука (0.0 - чистый, 1.0 - кошмар)
}

# Текущее состояние сессии
var current_voice_channel_id: String = ""
var muted_users: Array[int] = [] # Кого МЫ заглушили (не хотим слышать)
var is_self_muted: bool = false   # Замутили ли мы свой микрофон

# Структура чатов: { chat_id: { "messages": [...], "type": "group"|"private" } }
var chat_history: Dictionary = {}

func _ready():
	# Подключаемся к твоему низкоуровневому NetworkManager
	NetworkManager.packet_received.connect(_on_raw_packet_received)

# ==========================================
# ЛОГИКА ТЕКСТОВЫХ ЧАТОВ
# ==========================================

func send_text_message(chat_id: String, text_content: String):
	var payload = Dictionary()
	payload["chat_id"] = chat_id
	payload["text"] = text_content
	
	# Упаковываем в байты: [Тип Пакета (1 байт)] + [JSON строка]
	var data = PackedByteArray()
	data.append(PacketType.TEXT)
	data.append_array(var_to_bytes(payload))
	
	# Отправляем через твой NetworkManager всем
	NetworkManager.send_packet_to_all(data)
	
	# Сохраняем у себя локально
	_save_message_to_history(chat_id, multiplayer.get_unique_id(), text_content)

# ==========================================
# ЛОГИКА ГОЛОСОВЫХ КАНАЛОВ
# ==========================================

func join_voice_channel(channel_id: String):
	current_voice_channel_id = channel_id
	print("Подключился к голосовому каналу: ", channel_id)

func leave_voice_channel():
	current_voice_channel_id = ""

# Сюда твой менеджер захвата микрофона передает пожатый OPUS-кусок
func send_voice_frame(opus_data: PackedByteArray):
	if is_self_muted or current_voice_channel_id == "":
		return
		
	# Структура: [Тип Пакета (1 байт)] + [ID Канала (строка)] + [Данные звука]
	var data = PackedByteArray()
	data.append(PacketType.VOICE)
	
	# Упакуем ID канала, чтобы люди в других комнатах нас не слышали
	var channel_bytes = current_voice_channel_id.to_utf8_buffer()
	data.append(channel_bytes.size()) # Записываем длину строки, чтобы понять где кончается ID
	data.append_array(channel_bytes)
	data.append_array(opus_data)
	
	NetworkManager.send_packet_to_all(data)

# ==========================================
# ОБРАБОТКА ВХОДЯЩИХ ПАКЕТОВ
# ==========================================

func _on_raw_packet_received(sender_id: int, raw_data: PackedByteArray, timestamp: int):
	if raw_data.is_empty(): return
	
	var packet_type = raw_data[0]
	var body = raw_data.slice(1) # Отрезаем маркер типа
	
	match packet_type:
		PacketType.TEXT:
			var payload = bytes_to_var(body)
			_save_message_to_history(payload["chat_id"], sender_id, payload["text"])
			text_message_received.emit(payload["chat_id"], sender_id, payload["text"])
			
		PacketType.VOICE:
			if current_voice_channel_id == "": return # Мы не в голосовом канале
			if sender_id in muted_users: return       # Игрок у нас в муте
			
			# Извлекаем ID канала
			var id_size = body[0]
			var channel_id = body.slice(1, 1 + id_size).get_string_from_utf8()
			
			# Если пакет прилетел из другого канала — игнорируем
			if channel_id != current_voice_channel_id:
				return
				
			var opus_audio = body.slice(1 + id_size)
			
			# Передаем дальше в PlayerAudioPlayback (декодеру)
			# Тут же можно применить "custom_degradation", если нужно испортить звук на лету
			user_talking.emit(sender_id, opus_audio)

func _save_message_to_history(chat_id: String, sender_id: int, text: String):
	if not chat_history.has(chat_id):
		chat_history[chat_id] = {"messages": []}
	
	chat_history[chat_id]["messages"].append({
		"sender": sender_id,
		"text": text,
		"time": Time.get_datetime_dict_from_system()
	})
	# В будущем тут вызывается экспорт в JSON/Запись в зашифрованную папку пользователя
