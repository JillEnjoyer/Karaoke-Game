extends Control

var player_scene_state = ""

@onready var PlayerScene = $PlayerScene

const PLAYER_SCENE_WINDOW_RATIO = 1.5

func _ready() -> void:
	PlayerSceneSetup("window")
	PlayerScene.size = PlayerScene.size * PLAYER_SCENE_WINDOW_RATIO

func _process(delta: float) -> void:
	pass


func PlayerSceneSetup(size_flag) -> void:
	if size_flag == "window" and player_scene_state == "full_screen":
		PlayerScene.size = PlayerScene.size / PLAYER_SCENE_WINDOW_RATIO
	elif size_flag == "full_screen" and player_scene_state == "window":
		PlayerScene.size = PlayerScene.size * PLAYER_SCENE_WINDOW_RATIO
