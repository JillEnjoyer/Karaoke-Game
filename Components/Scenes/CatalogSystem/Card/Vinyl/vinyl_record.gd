extends Node3D

@onready var vinyl_plate = $VinylPlate
@onready var vinyl_plate_front = $VinylPlate/VinylFront
@onready var vinyl_plate_back = $VinylPlate/VinylBack

@onready var animation_player = $AnimationPlayer
@onready var fsm = FSMManager.new()

const fsm_states: Dictionary = {
	"closed_front": {
		"left": {
			"next_state": "closed_back",
			"animations": [
				{"name": "left_front", "reverse": false}
		]
		},
		"right": {
			"next_state": "closed_back",
			"animations": [
				{"name": "right_front", "reverse": false}
		]
		}
	},
	"closed_back": {
		"left": {
			"next_state": "closed_front",
			"animations": [
				{"name": "right_front", "reverse": true}
		]
		},
		"right": {
			"next_state": "closed_front",
			"animations": [
				{"name": "left_front", "reverse": true}
		]
		}
	}
}

var path_dict: Dictionary = {
	"vinyl_plate_front": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Vinyl_Plate][SIDE-A].png",
	"vinyl_plate_back": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Vinyl_Plate][SIDE-B].png"
}

var info_dict: Dictionary = {
	"franchise": "Hazbin Hotel"
}

const plate_size = 1.19


func _ready():
	add_child(fsm)
	fsm.setup(animation_player, "closed_front", get_transition_table())
	init(path_dict, info_dict)


func get_transition_table() -> Dictionary:
	return fsm_states


func input(event: InputEvent) -> void:
	if event.is_action_pressed("left"):
		fsm.handle_input("left")
	elif event.is_action_pressed("right"):
		fsm.handle_input("right")


func init(path_dict: Dictionary, info_dict: Dictionary) -> void:
	for key in path_dict.keys():
		var node = self.get(key)
		if node and node is Sprite3D:
			var tex_path = path_dict[key]
			apply_texture_to(node, tex_path)

	var franchise = info_dict.get("franchise", "Unknown")
	Debugger.debug("Franchise:", franchise)


func apply_texture_to(node: Sprite3D, texture_path: String) -> void:
	var tex: Texture2D = TextureLoader.load_texture_or_placeholder(texture_path)
	
	node.texture = tex
	node.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	node.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR

	var tex_width_px = tex.get_width()
	node.pixel_size = plate_size / float(tex_width_px)
