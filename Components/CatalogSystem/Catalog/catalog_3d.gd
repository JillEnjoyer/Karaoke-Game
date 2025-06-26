extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var world_environment = $WorldEnvironment.environment
@onready var main_slot = $CurrentLayerMarker
@onready var offscreen_marker = $OtherSlotsMarker


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
var all_level_objects := {}

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
const FLY_UP_OFFSET := Vector3(0, 3, -1)
const SPAWN_ANIM_OFFSET := Vector3(-3, 0, 0)


func _ready() -> void:
	_init_tween_controller()
	await get_tree().create_timer(0.1).timeout # Даем сцене полностью загрузиться
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
	elif event.is_action_pressed("shift"):
		print_storage_info()


func print_storage_info():
	print("=== Storage ===")
	for path in all_level_objects:
		print(" ", path, ": ", all_level_objects[path].objects.size(), " objects")
	print("Current: ", current_objects.size(), " objects")


func _clear_current_objects(animate: bool) -> void:
	"""Очищает текущие объекты с возможностью анимации"""
	if animate:
		for obj in current_objects:
			animate_fly_away(obj, true)
	else:
		for obj in current_objects:
			if is_instance_valid(obj):
				obj.queue_free()
	current_objects.clear()


func scan_folder() -> void:
	await get_tree().process_frame
	Debugger.info("Scanning: " + catalog_path)
	_clear_current_objects(false)  # Очищаем без анимации при первой загрузке
	await scan_current_stage_folder()


func scan_current_stage_folder() -> void:
	_combine_path_block()
	var entries := folder_scanner.scan_folder(current_path)
	
	_clear_current_objects(false)
	
	for i in range(entries.size()):
		var node = instantiate_catalog_item(entries[i])
		if node:
			# Устанавливаем имя объекта по имени папки
			node.name = entries[i]["name"]
			node.position = main_slot.position + ITEM_OFFSET * (i - focus_item)
			node.scale = Vector3.ZERO
			add_child(node)
			animate_item_appearance(node)
			current_objects.append(node)
	
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
	
	if node:
		node.reset_state() # Сбрасываем состояние нового объекта
	return node


func move_focus(direction: int) -> void:
	if current_objects.is_empty():
		return
	
	focus_item = wrapi(focus_item + direction, 0, current_objects.size())
	update_item_positions()
	sky_animate_sine_loop([5.0, 0.0, 0.3])


func update_item_positions() -> void:
	for i in range(current_objects.size()):
		var target_pos = main_slot.position + ITEM_OFFSET * (i - focus_item)
		var target_scale = Vector3.ONE * (1.0 if i == focus_item else 0.8)
		
		var tween = create_tween()
		tween.tween_property(current_objects[i], "position", target_pos, TRANSITION_DURATION)
		tween.parallel().tween_property(current_objects[i], "scale", target_scale, TRANSITION_DURATION)


func enter_next_stage(selected_folder: String) -> void:
	if current_objects.size() <= focus_item:
		return
	
	# Сохраняем текущий уровень
	all_level_objects[current_path] = {
		"objects": current_objects,
		"focus_index": focus_item,
		"stage": current_fsm_stage,
		"selected_name": current_objects[focus_item].name
	}
	
	# Анимация невыбранных объектов
	for i in range(current_objects.size()):
		if i != focus_item:
			animate_to_storage(current_objects[i])
	
	# Анимация выбранного объекта
	var selected = current_objects[focus_item]
	var tween = create_tween()
	tween.tween_property(selected, "position", 
		main_slot.position + SPAWN_ANIM_OFFSET, 
		TRANSITION_DURATION/2)
	tween.parallel().tween_property(selected, "scale", 
		Vector3.ONE * 1.2, TRANSITION_DURATION/2)
	
	tween.tween_callback(selected.play_open_animation.bind(TRANSITION_DURATION))
	tween.tween_callback(func():
		_add_new_path_block(selected_folder)
		current_fsm_stage += 1
		current_objects = []
		focus_item = 0
		scan_current_stage_folder()
		animate_fly_away(selected, true)
	)


func return_to_previous_stage() -> void:
	if all_level_objects.size() <= 1:
		Debugger.warning("On highest level. Can't go higher!")
		return
	
	# Получаем данные предыдущего уровня
	var prev_path = current_path.get_base_dir()
	var prev_data = all_level_objects.get(prev_path)
	
	if not prev_data:
		Debugger.error("Previous level data not found!")
		return
	
	_clear_current_objects(true)
	
	current_path = prev_path
	current_fsm_stage = prev_data.stage
	focus_item = prev_data.focus_index
	current_objects = []
	
	# Анимация возвращения объектов
	for i in range(prev_data.objects.size()):
		var obj = prev_data.objects[i]
		if is_instance_valid(obj):
			obj.reset_state()
			obj.position = main_slot.position + ITEM_OFFSET * (i - focus_item) + FLY_UP_OFFSET
			obj.scale = Vector3.ZERO
			add_child(obj)
			
			var tween = create_tween()
			tween.tween_property(obj, "position", 
				main_slot.position + ITEM_OFFSET * (i - focus_item), 
				TRANSITION_DURATION)
			tween.parallel().tween_property(obj, "scale", 
				Vector3.ONE, TRANSITION_DURATION)
			
			current_objects.append(obj)
	
	# Удаляем текущий уровень из хранилища
	all_level_objects.erase(current_path)
	_remove_from_path_block(path_block.back())


func animate_to_storage(obj: Node3D) -> void:
	obj.prepare_for_storage()
	var tween = create_tween()
	tween.tween_property(obj, "position", 
		offscreen_marker.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), 
		TRANSITION_DURATION)
	tween.parallel().tween_property(obj, "scale", 
		Vector3(0.3, 0.3, 0.3), TRANSITION_DURATION)

func animate_level_return(level_data: Dictionary) -> void:
	for i in range(level_data.objects.size()):
		var obj = level_data.objects[i]
		obj.reset_state()
		obj.position += FLY_UP_OFFSET
		obj.scale = Vector3.ZERO
		add_child(obj)
		
		var tween = create_tween()
		if i == level_data.focus_index:
			# Анимация для выбранного объекта
			tween.tween_property(obj, "position", 
				main_slot.position + SPAWN_ANIM_OFFSET, 
				TRANSITION_DURATION)
			tween.parallel().tween_property(obj, "scale", 
				Vector3.ONE * 1.2, TRANSITION_DURATION)
			
			tween.tween_callback(obj.play_close_animation.bind(TRANSITION_DURATION))
			
			tween.tween_property(obj, "position", 
				main_slot.position, TRANSITION_DURATION)
			tween.parallel().tween_property(obj, "scale", 
				Vector3.ONE, TRANSITION_DURATION)
		else:
			# Анимация для остальных объектов
			tween.tween_property(obj, "position", 
				main_slot.position + ITEM_OFFSET * (i - level_data.focus_index), 
				TRANSITION_DURATION)
			tween.parallel().tween_property(obj, "scale", 
				Vector3.ONE, TRANSITION_DURATION)


func clear_level_immediately(objects: Array) -> void:
	for obj in objects:
		obj.queue_free()

func animate_fly_away(obj: Node3D, delete_after: bool) -> void:
	var tween = create_tween()
	tween.tween_property(obj, "position", 
		obj.position + FLY_UP_OFFSET, TRANSITION_DURATION)
	tween.parallel().tween_property(obj, "scale", 
		Vector3.ZERO, TRANSITION_DURATION)
	if delete_after:
		tween.tween_callback(obj.queue_free)

func animate_item_appearance(item: Node3D) -> void:
	var tween = create_tween()
	tween.tween_property(item, "scale", 
		Vector3.ONE, TRANSITION_DURATION).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(item, "rotation:y", 
		randf_range(-0.1, 0.1), TRANSITION_DURATION)


func _combine_path_block() -> void:
	current_path = catalog_path
	for block in path_block:
		if block is String:
			current_path = current_path.path_join(block)
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
