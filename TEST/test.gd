extends Node2D

func _ready() -> void:
	while true:
		await get_tree().create_timer(0.1).timeout
		print("STEP")
