extends Node

var steam_app_id = "480"
var steam_id = ""
var user_name = ""


func _init() -> void:
	OS.set_environment("SteamAppID", steam_app_id)
	OS.set_environment("SteamGameID", steam_app_id)

func _ready() -> void:
	Steam.steamInit()

func get_user_ID():
	return

func is_steam_launched() -> bool:
	return Steam.isSteamRunning()

func verify_steam_id() -> String:
	steam_id = Steam.getSteamID()
	return steam_id

func get_steam_launcher_language() -> String:
	return Steam.getSteamUILanguage()
