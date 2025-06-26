extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var main_sleeve = $MainSleeve
@onready var main_sleeve_front_cover = $MainSleeve/RightHinge/MainSleeveFrontCover
@onready var main_sleeve_back_cover = $MainSleeve/MainSleeveBackCover
@onready var main_sleeve_left_page = $MainSleeve/RightHinge/MainSleeveFrontCover/MainSleeveLeftPageInside
@onready var main_sleeve_right_page = $MainSleeve/MainSleeveBackCover/MainSleeveRightPageInside

var animation_handler := AnimationHandler.new()
var fsm = FSMManager.new()

const fsm_states: Dictionary = {
	"closed_front": {
		"left": {
			"next_state": "closed_back",
			"animations": [
				{"name": "left_front_closed", "reverse": false}
			]
		},
		"right": {
			"next_state": "closed_back",
			"animations": [
				{"name": "right_front_closed", "reverse": false}
			]
		},
		"up": {
			"next_state": "opened_front",
			"animations": [
				{"name": "open_sleeve", "reverse": false}
			]
		}
	},
	"closed_back": {
		"left": {
			"next_state": "closed_front",
			"animations": [
				{"name": "right_front_closed", "reverse": true}
			]
		},
		"right": {
			"next_state": "closed_front",
			"animations": [
				{"name": "left_front_closed", "reverse": true}
			]
		}
	},
	"opened_front": {
		"left": {
			"next_state": "opened_back",
			"animations": [
				{"name": "left_front_opened", "reverse": false}
			]
		},
		"right": {
			"next_state": "opened_back",
			"animations": [
				{"name": "right_front_opened", "reverse": false}
			]
		},
		"up": {
			"next_state": "closed_front",
			"animations": [
				{"name": "open_sleeve", "reverse": true}
			]
		}
	},
	"opened_back": {
		"left": {
			"next_state": "opened_front",
			"animations": [
				{"name": "right_front_opened", "reverse": true}
			]
		},
		"right": {
			"next_state": "opened_front",
			"animations": [
				{"name": "left_front_opened", "reverse": true}
			]
		},
		"up": {
			"next_state": "closed_front",
			"animations": [
				{"name": "right_front_opened", "reverse": true},
				{"name": "open_sleeve", "reverse": true}
			]
		}
	}
}

var path_dict = {
	"main_sleeve_front_cover": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Main_Sleeve][Front].png",
	"main_sleeve_back_cover": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Main_Sleeve][Back].webp",
	"main_sleeve_left_page": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Main_Sleeve][Inside][LEFT].png",
	"main_sleeve_right_page": "X:/Projects/Godot/Karaoke/Catalog/Hazbin Hotel/Season 1/[VINYL]/[Main_Sleeve][Inside][RIGHT].png"
}

var info_dict = {
	"franchise": "Hazbin Hotel"
}


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
	elif event.is_action_pressed("up"):
		fsm.handle_input("up")


func init(path_dict: Dictionary, info_dict: Dictionary) -> void:
	for key in path_dict.keys():
		var node = self.get(key)
		if node and node is MeshInstance3D:
			var tex_path = path_dict[key]
			apply_texture_to(node, tex_path)

	var franchise = info_dict.get("franchise", "Unknown")
	Debugger.debug("Franchise:", franchise)


func apply_texture_to(node: MeshInstance3D, texture_path: String) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TextureLoader.load_texture_or_placeholder(texture_path)
	node.set_surface_override_material(0, mat)


func reset_state():
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	# Другие параметры сброса


func prepare_for_storage():
	# Уменьшаем детализацию для объектов в хранилище
	pass#$CollisionShape.disabled = true


func play_open_animation(duration: float):
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.1, duration/2)
	tween.tween_property(self, "scale", scale, duration/2)


func play_close_animation(duration: float):
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 0.9, duration/2)
	tween.tween_property(self, "scale", scale, duration/2)
