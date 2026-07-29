# card_background.gd
extends Control

@onready var animation_player = $AnimationPlayer
@onready var texture_rect = $TextureRect
@onready var media_player = $MediaPlayer

var config_parser = ConfigParser.new()
var config_path: String = ""

var texture_token: int = 0
var highlight_token: int = 0

var texture_visible: bool = false
var player_visible: bool = false


func _ready():
	pass


func apply_texture(texture: Texture = null) -> void:
	# Every button press increases ID, "dissmissing" previous await
	texture_token += 1
	var current_id = texture_token
	
	# small pause to not use animation with super-fast scrolling
	await get_tree().create_timer(0.5).timeout
	if current_id != texture_token: return

	texture_rect.texture = texture
	if not texture_visible:
		texture_visible = true
		animation_player.play("show_texture_rect")
func hide_texture() -> void:
	texture_token += 1
	if texture_visible:
		texture_visible = false
		animation_player.play_backwards("show_texture_rect")


## Highlight (video preview)
func show_highlight(song_path: String) -> void:
	media_player.playback_manager.wipe_managers()
	media_player.highlight_preinit()

	if song_path == "": return
	Debugger.debug("song_path: " + song_path)

	highlight_token += 1
	var current_id = highlight_token

	await get_tree().create_timer(2.5).timeout

	# If for that time ID has changed — means that song already changed
	if current_id != highlight_token:
		return
	
	config_path = song_path.path_join("config.json")
	if not FileAccess.file_exists(config_path):
		printerr("No Highlight available at: ", config_path)
		return
	# Read and parse ONLY IF timer sucessfully ended
	var data = FileAccess.get_file_as_string(config_path)

	var parsed_data = JSON.parse_string(data)
	if parsed_data == null or not parsed_data.has("highlights"):
		Debugger.error("Failed to parse JSON and/or highlights are missing: " + config_path)
		return

	animation_player.play("show_media_player")
	Debugger.debug("Highlight: " + str(parsed_data["highlights"]))
	Debugger.debug("Whole parsed data: " + str(parsed_data))
	media_player.highlight_init(parsed_data["highlights"], song_path, true)


func hide_highlight() -> void:
	highlight_token += 1 # interrupting potential highlight await
	animation_player.play_backwards("show_media_player")
	media_player.playback_manager.wipe_managers()
