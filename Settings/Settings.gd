extends Control

@onready var data_dict = {
	"resolution": Vector2(1280, 720),
	"framerate": 60,
	"hz": false,
	"v-sync": true,
	"catalog_path": ""
}

@onready var object_links = {
	"resolution": $ResolutionOptBtn,
	"framerate": $FrametimeOptBtn,
	"v-sync": $"V-SyncCB",
	"catalog_path": $CatalogPathLE
}

func _ready() -> void:
	fetch_settings()
	update_menu()


func fetch_settings() -> void:
	for key in data_dict:
		print("Key:", key, "Value:", Core.get_node("PreferencesData").getData(key))
	
	for key in data_dict:
		data_dict[key] = Core.get_node("PreferencesData").getData(key)
		print("Key:", key, "Value:", data_dict[key])
	

func update_menu() -> void:
	for key in object_links.keys():
		print(key)
		var ui_element = object_links[key]
		
		if ui_element is OptionButton:
			var data_value = data_dict[key]
			
			print(typeof(data_value), " -> ", "type of ", data_value)
			var string_value: String
			if typeof(data_value) == TYPE_VECTOR2:
				string_value = str(data_value.x) + "x" + str(data_value.y)
			elif typeof(data_value) == TYPE_INT:
				string_value = str(data_value)
			else:
				print("typeof() func is not supported: ", typeof(data_value))
			
			var index = get_index_by_text(ui_element, string_value)
			print("string = ", string_value, " / ", "index = ", index)
			
			if index != -1:
				ui_element.select(index)
			else:
				ui_element.select(0)
				print("Error: Failed collection of sellected item")
			
			print(ui_element.get_selected_id())
		
		elif ui_element is CheckBox:
			var data_value = data_dict[key]
			ui_element.button_pressed = bool(data_value)
		
		elif ui_element is LineEdit:
			var data_value = data_dict[key]
			ui_element.text = str(data_value)
		
		elif ui_element is Button:
			var data_value = data_dict[key]
			ui_element.pressed = bool(data_value)
		
		else:
			print("Неизвестный тип объекта для ключа:", key)


func get_index_by_text(option_button: OptionButton, text: String) -> int:
	for i in range(option_button.get_item_count()):
		print(option_button.get_item_text(i), " -> ", i)
		if option_button.get_item_text(i) == text:
			return i
	return -1


func _on_additional_btn_pressed() -> void:
	pass


func _on_back_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("main_menu")


func _on_apply_settings_btn_pressed() -> void:
	for key in data_dict:
		print("Key:", key, "Value:", data_dict[key])
		Core.get_node("PreferencesData").setData(key, data_dict[key])
		change_game_parameters(key, data_dict[key])
	Core.get_node("PreferencesData").save_config()


func change_game_parameters(parameter, parameter_value) -> void:
	if parameter == "resolution":
		DisplayServer.window_set_size(parameter_value)
		print("resolution changed")

	elif parameter == "framerate":
		ProjectSettings.set_setting("engine/core/target_fps", int(parameter_value))
		print("LALALALALALA", ProjectSettings.get_setting("engine/core/target_fps"))
		pass

	elif parameter == "v-sync":
		if parameter_value:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			print(DisplayServer.window_get_vsync_mode())
		print("v-sync ", DisplayServer.window_get_vsync_mode())
		


func _on_resolution_opt_btn_item_selected(index: int) -> void:
	var parts = object_links["resolution"].get_item_text(index).split("x")
	if parts.size() == 2:
		data_dict["resolution"] = Vector2(parts[0].to_float(), parts[1].to_float())
	
	print(data_dict["resolution"])

func _on_frametime_opt_btn_item_selected(index: int) -> void:
	data_dict["framerate"] = int(object_links["framerate"].get_item_text(index))
	print(data_dict["framerate"])

func _on_hz_btn_item_selected(index: int) -> void:
	pass

func _on_v_sync_cb_toggled(toggled_on: bool) -> void:
	data_dict["v_sync"] = object_links["v-sync"].button_pressed

func _on_catalog_path_le_text_changed(new_text: String) -> void:
	data_dict["catalog_path"] = new_text
