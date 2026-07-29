extends Control

signal action_requested(action_type, index)

@onready var label_name = $HBox/VBox/NameLbl
@onready var label_type = $HBox/VBox/TypeLbl
@onready var icon_rect = $HBox/Icon

var track_type: String = ""
var context_menu_manager: ContextMenuManager
var timeline: Control


func _ready() -> void:
	# Интегрируем хедер в общую систему контекстных меню через SignalBus
	if SignalBus.is_connected("context_menu_command_triggered", _on_global_menu_command):
		return
	SignalBus.context_menu_command_triggered.connect(_on_global_menu_command)


func import_managers(sm: SelectionManager, tp: Control, cm: ContextMenuManager, tl: Control) -> void:
	# selection_manager = sm
	# time_pointer = tp
	context_menu_manager = cm
	timeline = tl


func setup(node_name: String, type: String):
	track_type = type
	label_name.text = node_name
	label_type.text = type.to_upper()
	
	match type:
		"video":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/video.svg")
		"acapella":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/microphone.svg")
		"instrumental":
			icon_rect.texture = preload("res://Defaults/Materials/Icons/music.svg")


func _get_drag_data(_at_position):
	var preview = Label.new()
	preview.text = "Transfer track: " + label_name.text
	set_drag_preview(preview)
	return {"type": "reorder_track", "old_index": get_index()}


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var items: Array = []
		items.append("Move higher") # ID 0
		items.append("Move lower")  # ID 1
		
		# Динамически меняем состав меню в зависимости от типа трека
		if track_type == "acapella":
			items.append("Subtitle editor (Vosk)") # ID 2
			items.append("Delete track")           # ID 3
		else:
			items.append("Delete track")           # ID 2

		if context_menu_manager:
			context_menu_manager.show_menu(
				get_global_mouse_position(),
				items,
				self # Передаем себя как текущую цель (target) для менеджера
			)
		accept_event()


# Глобальный обработчик команд, вызываемый через SignalBus
func _on_global_menu_command(id: int, target: Control) -> void:
	Debugger.debug("_on_global_menu_command from track_header")
	# Если команда вызвана не для этого хедера, игнорируем её
	if target != self:
		Debugger.debug("Not the targer: " + str(target.name) + " != " + str(self.name))
		return
		
	#var command = ""
	
	# Парсим ID нажатого пункта обратно в текстовые команды
	"""
	if id == 0:
		command = "move_higher"
	elif id == 1:
		command = "move_lower"
	elif id == 2:
		if track_type == "acapella":
			command = "vosk_subtitles"
		else:
			command = "delete_track"
	elif id == 3 and track_type == "acapella":
		command = "delete_track"
		"""

	#Debugger.debug("command: " + command)
	# Отправляем сигнал наверх (в timeline.gd) для выполнения физического действия
	action_requested.emit(id, get_index(), timeline.vbox_timelines.get_child(get_index()).initial_path)
