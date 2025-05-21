extends Control

@onready var LoadingTexture = $LoadingAnimation
@onready var LoadingLbl = $LoadingFileName

var interrupt_animation = false
var animation_stopped = false

var user_timestep = 0.1
var animation_images = []

func _ready() -> void:
	pass


#func update(new_percent: int, new_file: String) -> void:
	


func _process(delta: float) -> void:
	if not interrupt_animation:
		if not animation_stopped:
			pass
			#play_animation()


func play_animation(user_timestep) -> void:
	animation_stopped = false
	for image in animation_images:
		LoadingTexture.texture = image
		await get_tree().create_timer(user_timestep).timeout
	animation_stopped = true


func import_loading_images(folder_path: String) -> void:
	var folder = "" # open folder, read all files
	
