extends Control

# Сигнал теперь возвращает словарь с настройками и массивом объектов-врапперов
signal export_files(export_data: Dictionary)

@onready var language_ob: OptionButton = $VBoxContainer/LanguageHBox/LanguageOB
@onready var prj_name_le: LineEdit = $VBoxContainer/NameHBox/PrjNameLE
@onready var cancel_btn: Button = $ControlHBox/CancelBtn
@onready var export_btn: Button = $ControlHBox/ExportBtn

var _incoming_items: Array = []
var _checkboxes: Array[CheckBox] = []
var file_list_container: VBoxContainer

# Метод инициализации (принимает массив словарей с информацией об элементах таймлайна)
func init_window(items_info: Array, default_project_name: String = "MyCoolProject") -> void:
	_incoming_items = items_info
	set_meta("default_name", default_project_name)

func _ready() -> void:
	cancel_btn.pressed.connect(_on_cancel_pressed)
	export_btn.pressed.connect(_on_export_pressed)
	
	if has_meta("default_name"):
		prj_name_le.text = get_meta("default_name")
	
	_setup_file_list_ui()
	_populate_list()

func _setup_file_list_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.layout_mode = 1
	scroll.anchors_preset = Control.PRESET_TOP_WIDE
	scroll.offset_left = 50
	scroll.offset_top = 50
	scroll.offset_right = -50
	scroll.offset_bottom = 700 
	
	var panel_bg = Panel.new()
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_child(panel_bg)
	
	file_list_container = VBoxContainer.new()
	file_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	file_list_container.add_theme_constant_override("separation", 10) 
	scroll.add_child(file_list_container)
	
	add_child(scroll)

func _populate_list() -> void:
	for item in _incoming_items:
		var cb = CheckBox.new()
		# Выводим уникальный размеченный текст: "Акапелла (The Guy): all.mp3"
		cb.text = item["display_text"]
		cb.button_pressed = true 
		
		# Сохраняем прямую ссылку на ControllerWrapper прямо внутри чекбокса
		cb.set_meta("wrapper_node", item["wrapper"])
		#cb.theme_override_font_sizes.font_size = 28
		
		file_list_container.add_child(cb)
		_checkboxes.append(cb)

func _on_export_pressed() -> void:
	var selected_wrappers = []
	
	# Собираем ссылки на ноды-врапперы только от отмеченных чекбоксов
	for cb in _checkboxes:
		if cb.button_pressed:
			selected_wrappers.append(cb.get_meta("wrapper_node"))
			
	var export_data = {
		"project_name": prj_name_le.text.strip_edges(),
		"language": language_ob.get_item_text(language_ob.selected),
		"wrappers": selected_wrappers # Передаем массив объектов назад в EditorScene
	}
	
	export_files.emit(export_data)
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()
