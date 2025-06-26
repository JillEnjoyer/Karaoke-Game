extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var world_environment = $WorldEnvironment.environment

var vinyl_box = UIManager.get_desired_node("vinyl_box")
var main_sleeve = UIManager.get_desired_node("main_sleeve")
var inner_sleeve = UIManager.get_desired_node("inner_sleeve")
var vinyl_record = UIManager.get_desired_node("vinyl_record")

var catalog_path: String = PreferencesData.getData("catalog_path")
var folder_scanner = FolderScanner.new()
var tween_controller = TweenController.new()

var current_fsm_stage := Stage.VINYL_BOX
var stage_stack := []
var current_objects := []
var focus_item: int = 0
var path_block: Array = []
var current_path: String = ""

enum Stage {
	VINYL_BOX,
	MAIN_SLEEVE,
	INNER_SLEEVE,
	VINYL_PLATE
}

const anim_presets := {
	Stage.VINYL_BOX: [180.0, 120.0, 1.2],
	Stage.MAIN_SLEEVE: [120.0, 100.0, 1.0],
	Stage.INNER_SLEEVE: [100.0, 80.0, 1.0],
	Stage.VINYL_PLATE: [80.0, 60.0, 1.0],
	"Sine": ["X", "Y", 1.5]
}

const TRANSITION_DURATION := 0.5
const ITEM_OFFSET := Vector3(1.5, 0, 0)
const FLY_UP_OFFSET := Vector3(0, 3, 0)


func _ready() -> void:
	_init_tween_controller()
	scan_folder()


func _init_tween_controller() -> void:
	UIManager.new_child(tween_controller, self)
	await get_tree().process_frame
	tween_controller.ensure_tween_ready()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right"):
		move_focus(1)
	elif event.is_action_pressed("left"):
		move_focus(-1)
	elif event.is_action_pressed("down"):
		if current_objects.size() > focus_item:
			var selected = current_objects[focus_item]
			enter_next_stage(selected.get_name())
	elif event.is_action_pressed("up"):
		return_to_previous_stage()


func scan_folder() -> void:
	await get_tree().process_frame
	Debugger.info("Scanning: " + catalog_path)
	await scan_current_stage_folder()


func scan_current_stage_folder() -> void:
	_combine_path_block()
	var entries := folder_scanner.scan_folder(current_path)
	
	#clear_current_objects(false)  # Не анимируем при первой загрузке
	
	for i in range(entries.size()):
		var node = instantiate_catalog_item(entries[i])
		if node:
			node.position = ITEM_OFFSET * (i - focus_item)
			add_child(node)
			current_objects.append(node)
			animate_item_appearance(node)
	
	update_item_positions()


func instantiate_catalog_item(entry: Dictionary) -> Node3D:
	Debugger.debug(
		"\nname = " + str(entry["name"]) +
		"\nis_dir = " + str(entry["is_dir"]) +
		"\ntype_hint = " + str(entry["type_hint"])
	)

	var node: Node3D = null
	match current_fsm_stage:
		Stage.VINYL_BOX:
			if entry["type_hint"] == "catalog":
				node = vinyl_box.instantiate()
		Stage.MAIN_SLEEVE:
			if entry["type_hint"] == "franchise":
				node = main_sleeve.instantiate()
		Stage.INNER_SLEEVE:
			if entry["type_hint"] == "album":
				node = inner_sleeve.instantiate()
		Stage.VINYL_PLATE:
			if entry["type_hint"] == "song":
				node = vinyl_record.instantiate()
	return node


func move_focus(direction: int) -> void:
	if current_objects.is_empty():
		return
	
	focus_item = wrapi(focus_item + direction, 0, current_objects.size())
	update_item_positions()
	#sky_animate_sine_loop([180.0, 177.5, 0.3])


func update_item_positions() -> void:
	for i in range(current_objects.size()):
		var target_pos = ITEM_OFFSET * (i - focus_item)
		var target_scale = Vector3.ONE * (1.0 if i == focus_item else 0.8)
		
		var tween = create_tween()
		tween.tween_property(current_objects[i], "position", target_pos, TRANSITION_DURATION)
		tween.parallel().tween_property(current_objects[i], "scale", target_scale, TRANSITION_DURATION)


func enter_next_stage(selected_folder: String) -> void:
	if current_objects.size() <= focus_item:
		return
	
	stage_stack.push_back({
		"stage": current_fsm_stage,
		"path": current_path,
		"objects": current_objects.duplicate(),
		"focus_item": focus_item,
		"selected_object": current_objects[focus_item]
	})
	
	for i in range(current_objects.size()):
		if i != focus_item:
			animate_fly_away(current_objects[i], true)
	
	var selected = current_objects[focus_item]
	var tween = create_tween()
	tween.tween_property(selected, "scale", Vector3.ONE * 1.2, TRANSITION_DURATION/2)
	tween.tween_property(selected, "scale", Vector3.ONE, TRANSITION_DURATION/2)
	
	await tween.finished
	
	_clear_current_stage(false)
	_add_new_path_block(selected_folder)
	current_fsm_stage += 1
	
	await sky_animate_parabolic(anim_presets[current_fsm_stage])
	await scan_current_stage_folder()
	
	animate_fly_away(selected, true)


func return_to_previous_stage() -> void:
	if stage_stack.size() == 0:
		Debugger.warning("On highest level. Can't go higher!")
		return
	
	_clear_current_stage(true)
	
	var prev = stage_stack.pop_back()
	current_fsm_stage = prev.stage
	current_path = prev.path
	focus_item = prev.focus_item
	
	var returning_obj = prev.selected_object
	returning_obj.position += FLY_UP_OFFSET
	returning_obj.scale = Vector3.ZERO
	add_child(returning_obj)
	
	var tween = create_tween()
	tween.tween_property(returning_obj, "position", returning_obj.position - FLY_UP_OFFSET, TRANSITION_DURATION)
	tween.parallel().tween_property(returning_obj, "scale", Vector3.ONE, TRANSITION_DURATION)
	
	current_objects = prev.objects
	for obj in current_objects:
		if obj != returning_obj:
			add_child(obj)
	
	update_item_positions()
	_remove_from_path_block(path_block.back())
	await sky_animate_parabolic(anim_presets[current_fsm_stage])


func _clear_current_stage(animate: bool) -> void:
	if animate:
		for obj in current_objects:
			animate_fly_away(obj, true)
	else:
		for obj in current_objects:
			obj.queue_free()
	current_objects.clear()


func animate_fly_away(item: Node3D, delete_after: bool) -> void:
	var tween = create_tween()
	tween.tween_property(item, "position", item.position + FLY_UP_OFFSET, TRANSITION_DURATION)
	tween.parallel().tween_property(item, "scale", Vector3.ZERO, TRANSITION_DURATION)
	if delete_after:
		tween.tween_callback(item.queue_free)


func animate_item_appearance(item: Node3D) -> void:
	item.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(item, "scale", Vector3.ONE, TRANSITION_DURATION).set_trans(Tween.TRANS_BACK)


func _combine_path_block() -> void:
	current_path = catalog_path
	for block in path_block:
		if block is String:
			current_path += "/" + block
		else:
			Debugger.error("Block: " + String(block) + " is not a string")
	Debugger.debug("current_path after combination: " + current_path)


func _add_new_path_block(new_block: String) -> void:
	path_block.append(new_block)
func _remove_from_path_block(block: String) -> void:
	path_block.remove_at(path_block.find(block))


func sky_animate_parabolic(start, end := 0.0, duration := 1.0) -> void:
	if typeof(start) == TYPE_ARRAY:
		if start.size() >= 3:
			end = start[1]
			duration = start[2]
			start = start[0]
		else:
			Debugger.error("Invalid parameter: expected Array of size ≥ 3")
			return
	await tween_controller.animate_parabolic(world_environment, "sky_custom_fov", start, end, duration)


func sky_animate_sine_loop(amplitude, base_value := 0.0, duration := 1.0) -> void:
	if typeof(amplitude) == TYPE_ARRAY:
		if amplitude.size() >= 3:
			base_value = amplitude[1]
			duration = amplitude[2]
			amplitude = amplitude[0]
		else:
			Debugger.error("Invalid parameter: expected Array of size ≥ 3")
			return
	await tween_controller.animate_sine_loop(world_environment, "sky_custom_fov", amplitude, base_value, duration)
