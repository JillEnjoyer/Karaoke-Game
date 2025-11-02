extends Control

@onready var data_dict = {
	"resolution": [1920, 1080],
	"framerate": 60,
	"hz": false,
	"v-sync": true,
	"catalog_path": "",
	"catalog_style": "2d" # 2d/3d
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
		Debugger.info("Key: " + key + ", Value: " + str(PreferencesData.getData(key)))
	
	for key in data_dict:
		data_dict[key] = PreferencesData.getData(key)
		Debugger.info("Key: " + key + ", Value: " + str(data_dict[key]))
	

func update_menu() -> void:
	for key in object_links.keys():
		Debugger.debug(key)
		var ui_element = object_links[key]
		
		"""if ui_element is OptionButton:
			var data_value = data_dict[key]
			
			Debugger.info(str(typeof(data_value)) + " -> type of " + str(data_value))
			var string_value: String
			if typeof(data_value) == TYPE_ARRAY:
				string_value = str(int(data_value[0])) + "x" + str(int(data_value[1]))
			elif typeof(data_value) == TYPE_INT:
				string_value = str(data_value)
			else:
				Debugger.warning("typeof() func is not supported: " + str(typeof(data_value)))
			
			var index = get_index_by_text(ui_element, string_value)
			Debugger.info("string = " + string_value + " / index = " + str(index))
			
			if index != -1:
				ui_element.select(index)
			else:
				ui_element.select(0)
				Debugger.error("Failed collection of sellected item")
			
			Debugger.info(str(ui_element.get_selected_id()))"""

		if ui_element is OptionButton:
			var data_value = data_dict[key]
			var string_value := ""

			# Разрешение: [1280, 720] или ["1280", "720"]
			if (typeof(data_value) == TYPE_ARRAY or typeof(data_value) == TYPE_PACKED_STRING_ARRAY) and data_value.size() == 2:
				string_value = str(int(data_value[0])) + "x" + str(int(data_value[1]))

			# FPS или другое целое значение
			elif typeof(data_value) == TYPE_INT:
				string_value = str(data_value)

			# fallback
			else:
				Debugger.warning("Unsupported data type for OptionButton: " + str(typeof(data_value)) + " " + str(data_value))
				ui_element.select(0)
				return

			var index = get_index_by_text(ui_element, string_value)
			Debugger.info("string = " + string_value + " / index = " + str(index))

			if index != -1:
				ui_element.select(index)
			else:
				ui_element.select(0)
				Debugger.error("Failed to select item for value: " + string_value)

			Debugger.info("Selected ID: " + str(ui_element.get_selected_id()))

		
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
			Debugger.error("Unknown type of object for the key: " + key)


func get_index_by_text(option_button: OptionButton, text: String) -> int:
	for i in range(option_button.get_item_count()):
		Debugger.info(option_button.get_item_text(i) + " -> " + str(i))
		if option_button.get_item_text(i) == text:
			return i
	return -1


func _on_additional_btn_pressed() -> void:
	Debugger.not_implemented("Not implemented yet. Planned additional settings + debug tools for end user")


func _on_back_btn_pressed() -> void:
	UIManager.cleanup_tree()
	UIManager.show_ui("main_menu")


func _on_apply_settings_btn_pressed() -> void:
	#data_dict # for save
	for key in data_dict:
		Debugger.info("Key: " + key + "Value: " + str(data_dict[key]))
		PreferencesData.setData(key, data_dict[key])
		change_game_parameter(key, data_dict[key])
	PreferencesData.save_config()


func change_game_parameter(parameter, parameter_value) -> void:
	if parameter == "resolution":
		Debugger.info(type_string(typeof(parameter_value)))
		get_window().size = Vector2(int(parameter_value[0]), int(parameter_value[1]))
		DisplayServer.window_set_size(Vector2i(int(parameter_value[0]), int(parameter_value[1])))
		Debugger.info("resolution changed")

	elif parameter == "framerate":
		ProjectSettings.set_setting("engine/core/target_fps", int(parameter_value))
		Debugger.debug("target_fps" + str(ProjectSettings.get_setting("engine/core/target_fps")))

	elif parameter == "v-sync":
		if parameter_value:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Debugger.info(str(DisplayServer.window_get_vsync_mode()))
		Debugger.info("v-sync " + str(DisplayServer.window_get_vsync_mode()))
		

func _on_resolution_opt_btn_item_selected(index: int) -> void:
	var parts = object_links["resolution"].get_item_text(index).split("x")
	if parts.size() == 2:
		data_dict["resolution"] = [int(parts[0]), int(parts[1])]
	
	Debugger.info(str(data_dict["resolution"]))


func _on_frametime_opt_btn_item_selected(index: int) -> void:
	data_dict["framerate"] = int(object_links["framerate"].get_item_text(index))
	print(data_dict["framerate"])


func _on_hz_btn_item_selected(index: int) -> void:
	Debugger.not_implemented("Not implemented yet")


func _on_v_sync_cb_toggled(toggled_on: bool) -> void:
	data_dict["v_sync"] = object_links["v-sync"].button_pressed


func _on_catalog_path_le_text_changed(new_text: String) -> void:
	data_dict["catalog_path"] = new_text
