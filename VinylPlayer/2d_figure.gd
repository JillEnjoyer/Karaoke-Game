extends Control

@onready var texture_rect = $TextureRect

@onready var figure_path = "W:/Projects/Godot/Karaoke/Mat/Ext"
@onready var state = true
@onready var tex_path = []
@onready var tex = []

func _ready() -> void:
	tex_init()
	anim_exec()

func tex_init():
	var file_count = count_files_in_directory(figure_path)
	if file_count > 0:
		tex_path.sort_custom(func(a, b): return extract_number(a) < extract_number(b))

		for n in range(file_count):
			if tex_path.size() > n:
				var image = Image.new()
				if image.load(tex_path[n]) == OK:
					var texture = ImageTexture.create_from_image(image)
					if texture:
						tex.append(texture)
						print("Loaded:", tex_path[n])
					else:
						print("Error with texture creation:", tex_path[n])
				else:
					print("Error with image loading:", tex_path[n])

func extract_number(filename: String) -> int:
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(filename)
	if result:
		return result.get_string().to_int()
	return 0


func anim_exec():
	while state:
		for n in range(tex.size()):
			print(n)
			texture_rect.texture = tex[n]
			await get_tree().create_timer(0.075).timeout

func count_files_in_directory(path: String) -> int:
	var dir = DirAccess.open(path)
	if dir == null:
		print("Error: failed to open directory", path)
		return 0
	
	dir.list_dir_begin()
	var count = 0
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			tex_path.append(path + "/" + file_name)
			count += 1
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return count

func anim_stop():
	state = false
