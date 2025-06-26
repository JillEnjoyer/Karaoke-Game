extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var inner_sleeve = $InnerSleeve
@onready var inner_sleeve_front_cover = $InnerSleeve/InnerSleeveFrontCover
@onready var inner_sleeve_back_cover = $InnerSleeve/InnerSleeveBackCover

var animation_handler := AnimationHandler.new()

enum SleeveState {
	CLOSED_FRONT,
	CLOSED_BACK
}

var path_dict = {
	"inner_sleeve_front_cover": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Inner_Sleeve][Front].png",
	"inner_sleeve_back_cover": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Inner_Sleeve][Back].png"
}

var info_dict = {
	"franchise": "Hazbin Hotel"
}

var current_state: SleeveState = SleeveState.CLOSED_FRONT
var previous_state: SleeveState = SleeveState.CLOSED_FRONT
var input_buffer: Array = []
var is_processing := false


func _ready() -> void:
	init(path_dict, info_dict)


func init(path_dict: Dictionary, info_dict: Dictionary) -> void:
	for key in path_dict.keys():
		var node = self.get(key)
		if node and node is MeshInstance3D:
			var tex_path = path_dict[key]
			apply_texture_to(node, tex_path)

	var franchise = info_dict.get("franchise", "Unknown")
	print("Franchise:", franchise)


func apply_texture_to(node: MeshInstance3D, texture_path: String) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TextureLoader.load_texture_or_placeholder(texture_path)
	node.set_surface_override_material(0, mat)


func input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	
	if event.is_action_pressed("left"):
		input_buffer.append("left")
	elif event.is_action_pressed("right"):
		input_buffer.append("right")
	elif event.is_action_pressed("up"):
		input_buffer.append("toggle")
	elif event.is_action_pressed("down"):
		input_buffer.append("special")
	
	_process_buffer()


func _process_buffer() -> void:
	if is_processing or input_buffer.is_empty():
		return
	
	is_processing = true
	var command = input_buffer.pop_front()
	
	match command:
		"left":
			await _handle_spin_left()
		"right":
			await _handle_spin_right()
	
	is_processing = false
	_process_buffer()


func _handle_spin_left() -> void:
	match current_state:
		SleeveState.CLOSED_FRONT:
			await animation_handler.run_animation(animation_player, "left_front", false)
			current_state = SleeveState.CLOSED_BACK
		
		SleeveState.CLOSED_BACK:
			await animation_handler.run_animation(animation_player, "right_front", true)
			current_state = SleeveState.CLOSED_FRONT
			
	print(SleeveState.find_key(current_state))


func _handle_spin_right() -> void:
	match current_state:
		SleeveState.CLOSED_FRONT:
			await animation_handler.run_animation(animation_player, "right_front", false) #left_front_opened
			current_state = SleeveState.CLOSED_BACK
		
		SleeveState.CLOSED_BACK:
			await animation_handler.run_animation(animation_player, "left_front", true) #left_front_opened
			current_state = SleeveState.CLOSED_FRONT
			
	print(SleeveState.find_key(current_state))
