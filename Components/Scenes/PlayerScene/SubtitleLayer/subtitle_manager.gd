extends Control
class_name SubtitleManager

signal subtitles_finished

@onready var subtitles_container: VBoxContainer = $SubtitlesContainer

var subtitle_list: Array = []
var current_time: float = 0.0
var playing: bool = false
var game_role_mode: String = "show_names" # "show_names", "show_numbers", "hidden"

# Храним ссылки на инстанциированные строки на экране: { "текст_строки": Node }
var active_spawned_nodes: Dictionary = {}

func _ready() -> void:
	pass

# Теперь менеджер просто принимает массив
func init(subtitles: Array, type: String = "karaoke", characters: Array = []) -> void:
	wipe_manager()
	subtitle_list = subtitles # <--- Никаких парсеров

func wipe_manager() -> void:
	subtitle_list.clear()
	current_time = 0.0
	playing = false
	active_spawned_nodes.clear()
	if subtitles_container:
		for child in subtitles_container.get_children():
			child.queue_free()

func update_timer(player_scene_logical_time: float, delta: float = 0.0) -> void:
	if not playing or subtitle_list.is_empty():
		return
		
	current_time = player_scene_logical_time
	
	var lines_to_show := []
	for line_data in subtitle_list:
		# БУФЕР +1.5 сек: даем джамперу время красиво упасть перед удалением строки
		if current_time >= line_data.get("start_time", 0.0) and current_time <= (line_data.get("end_time", 0.0) + 1.5):
			lines_to_show.append(line_data)
			
	# 1. Удаляем отзвучавшие строки
	var keys_to_erase = []
	for line_text in active_spawned_nodes.keys():
		var still_active := false
		for active_line in lines_to_show:
			if active_line["text"] == line_text:
				still_active = true
				break
		if not still_active:
			if is_instance_valid(active_spawned_nodes[line_text]):
				active_spawned_nodes[line_text].queue_free()
			keys_to_erase.append(line_text)
			
	for k in keys_to_erase:
		active_spawned_nodes.erase(k)

	# 2. Спавним новые строки (VBoxContainer сам их расставит по вертикали)
	for line_data in lines_to_show:
		var txt = line_data["text"]
		if not active_spawned_nodes.has(txt):
			var line_instance = UIManager.get_desired_node("KaraokeStyleLine").instantiate()
			subtitles_container.add_child(line_instance)
			
			var speaker = line_data.get("character", "all")
			line_instance.setup(
				speaker, 
				line_data.get("words", []), 
				line_data.get("start_time", 0.0), 
				line_data.get("end_time", 0.0),
				game_role_mode
			)
			active_spawned_nodes[txt] = line_instance

	# 3. Делегируем обновление времени внутрь каждой строки
	for txt in active_spawned_nodes:
		if is_instance_valid(active_spawned_nodes[txt]):
			active_spawned_nodes[txt].update_time(current_time)

func seek(new_logical_time: float) -> void:
	current_time = new_logical_time
	# При сике полностью очищаем экран, следующий апдейт заспавнит нужные строки
	for child in subtitles_container.get_children():
		child.queue_free()
	active_spawned_nodes.clear()
	
	update_timer(current_time, 0.0)
	Debugger.info("Subtitles seeked to: " + str(new_logical_time))

func start(time: float = 0.0) -> void:
	seek(time)
	playing = true

func resume() -> void:
	playing = true

func pause() -> void:
	playing = false

func stop() -> void:
	playing = false
	seek(0.0)

func set_game_role_mode(new_mode: String) -> void:
	game_role_mode = new_mode
	seek(current_time)
