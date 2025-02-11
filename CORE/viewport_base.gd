extends Control

@onready var scene_root = $SubViewportContainer/SubViewport 

func _ready() -> void:
	var menu = preload("res://MainMenu/MainMenu.tscn").instantiate()
	scene_root.call_deferred("add_child", menu)
	
	await get_tree().create_timer(1).timeout
	
	var viewport = preload("res://WebSocket/web_socket.tscn").instantiate()
	get_tree().get_root().call_deferred("add_child", viewport)
