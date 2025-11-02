extends CanvasLayer
class_name ContextMenuManager

var menu := PopupMenu.new()

func _ready():
	add_child(menu)
	menu.connect("id_pressed", _on_id_pressed)
	menu.hide()

var _callback: Callable = func(id): pass

func show_menu(pos: Vector2, items: Array[String], callback: Callable):
	menu.clear()
	for i in items.size():
		menu.add_item(items[i], i)
	_callback = callback
	menu.set_position(pos)
	menu.popup()

func _on_id_pressed(id):
	_callback.call(id)
