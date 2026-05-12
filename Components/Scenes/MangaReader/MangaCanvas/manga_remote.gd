extends Control

signal manga_page_requested(page_num)
signal next_page_requested
signal prev_page_requested
signal toggle_remote_requested
signal manga_file_selected(path)

@onready var input_timer: Timer = Timer.new()
@onready var current_page_te := $HBoxContainer/CurrentPageTE
@onready var page_amount_lbl := $HBoxContainer/PageAmountLbl

var regex = RegEx.new()
var fm: FileDialog

var is_remote_hidden := true
var is_user_input := false
var current_page := 0
var total_pages := 0


func _ready() -> void:
	## current page input
	regex.compile("^[0-9]*$")

	input_timer.wait_time = 3.0
	input_timer.one_shot = true
	input_timer.timeout.connect(_on_input_timer_timeout)
	add_child(input_timer)

func _on_input_timer_timeout() -> void:
	Debugger.info("User finished typing. Navigating to page: " + str(current_page))
	# TODO: clear all pages and ask for new ones that requested by user
	manga_page_requested.emit(current_page)


func _on_back_btn_pressed() -> void:
	prev_page_requested.emit()


func _on_next_btn_pressed() -> void:
	next_page_requested.emit()


func _on_hide_btn_pressed() -> void:
	is_remote_hidden = !is_remote_hidden
	toggle_remote_requested.emit(is_remote_hidden)


func _on_manga_btn_pressed() -> void:
	if not fm:
		fm = FileDialog.new()

		fm.file_mode = FileDialog.FILE_MODE_OPEN_ANY
		fm.access = FileDialog.ACCESS_FILESYSTEM 

		fm.clear_filters()
		fm.add_filter("*.pdf", "PDF Documents")
		fm.add_filter("*.zip, *.cbz", "Zip Archives")
		fm.add_filter("*.7z", "7zip Archives")
		
		fm.dir_selected.connect(_on_path_selected)
		fm.file_selected.connect(_on_path_selected)

		owner.add_child(fm)

	fm.popup_centered_clamped(Vector2i(800, 600))


func _on_path_selected(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		if _directory_has_images(path):
			manga_file_selected.emit(path)
		else:
			Debugger.warning("Folder contains no suitable images!")
	else:
		# If it is a file (pdf/zip/etc), sending path to worker...
		manga_file_selected.emit(path)


func _directory_has_images(path: String) -> bool:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var img_exts = ["jpg", "jpeg", "png", "webp", "bmp"]
		
		while file_name != "":
			if not dir.current_is_dir():
				var ext = file_name.get_extension().to_lower()
				if ext in img_exts:
					return true # If at least one image is found, we consider this folder valid
			file_name = dir.get_next()
	return false


func _on_current_page_te_text_changed() -> void:
	var new_text = current_page_te.text
	Debugger.info("User input : " + new_text)
	
	if not regex.search(new_text):
		var filtered = ""
		for c in new_text:
			if c in "0123456789":
				filtered += c
		current_page_te.text = filtered
		current_page_te.caret_column = filtered.length()
		return
	
	if new_text == "":
		input_timer.stop()
		return

	current_page = int(new_text)
	if current_page >= total_pages:
		current_page = total_pages

	input_timer.start()


func update_current_page_num(page_num: int) -> void:
	current_page = page_num
	
	# Block signals to prevent recursive triggering when we update the text programmatically
	current_page_te.set_block_signals(true)
	current_page_te.text = str(page_num)
	current_page_te.set_block_signals(false)


func update_total_pages(page_count: int) -> void:
	total_pages = page_count
	page_amount_lbl.text = str(page_count)
