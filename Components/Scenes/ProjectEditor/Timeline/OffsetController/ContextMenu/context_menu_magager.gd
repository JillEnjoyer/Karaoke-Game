extends CanvasLayer
class_name ContextMenuManager

var menu := PopupMenu.new()
var current_target: Control = null

func _ready():
	add_child(menu)
	menu.id_pressed.connect(_on_id_pressed)
	menu.hide()


func show_menu(pos: Vector2, items: Array, target: Control):
	menu.clear()
	current_target = target
	for i in items.size():
		menu.add_item(items[i], i)
	menu.position = pos
	menu.popup()


func _on_id_pressed(id: int):
	if is_instance_valid(current_target):
		SignalBus.context_menu_command_triggered.emit(id, current_target)
