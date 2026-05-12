extends Control


func _ready() -> void:
	await get_tree().create_timer(1).timeout
	UIManager.show_ui("WebSocket", "core")
