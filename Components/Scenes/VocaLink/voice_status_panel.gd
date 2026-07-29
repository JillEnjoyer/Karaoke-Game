extends HBoxContainer

## DICT COLOR: Green: 1eaa64, Red: ef524d, Yellow: f5b21f, Grey: a5a9a2

@onready var user_avatar: TextureRect = $UserProfile/Avatar
@onready var user_status_rect: ColorRect = $UserProfile/Avatar/StatusDot

@onready var username: Label = $UserProfile/TextInfo/Username
@onready var status_text: Label = $UserProfile/TextInfo/StatusText

@onready var mute_button: Button = $ControlButtons/MuteButton
@onready var deafen_button: Button = $ControlButtons/DeafenButton
@onready var settings_button: Button = $ControlButtons/SettingsButton

var user_steamid: int = -1
var user_manager = null

func _ready() -> void:
	pass


func update(current_user_status, new_message_poll: int = 0) -> void: ## only system manager does process, others are called when needed
	## works with statuses, with new message icon
	apply_new_user_status(current_user_status)
	


##TODO: Ввод: Менеджер пользователей ссылка (штука, что должна брать SteamID игрока и находить для него имя и аватар в базе)
func init(global_user_manager, steamid) -> void:
	user_manager = global_user_manager
	user_steamid = steamid
	
	## var result:{} = user_manager.get_userdata(user_steamid)
	## apply_avatar(result["avatar_path"]) ## должен быть возвращен в виде ссылки на изображения с диска
	## 


func apply_avatar(image_path: String) -> void:
	pass #user_avatar = ImageLoader.load_image(image_path)


func apply_new_user_status(current_user_status):
	pass
	## take status name and apply color to it
	user_status_rect.color = Color.WHITE 
