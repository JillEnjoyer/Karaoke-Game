extends Control

@onready var host_button = $HostBtn
@onready var client_button = $ClientBtn
@onready var player_container = $ScrollContainer/VBoxContainer
@onready var entry_panel = $EntryPanel
@onready var animation_player = $AnimationPlayer

var server = ClientServer.new()

func _ready() -> void:
	player_container.add_child(UIManager.get_desired_node("player_block").instantiate())
	entry_panel.connect("mouse_entered", Callable(self, "show_host_panel"))

"""
1. Нажимая на Хост кнопку - создать комнату, имея свой IP, PORT, Спец код для подключения. Наверное этот этап должен проводить Port forwarding
2. client кнопка спросит данные и попробует подключится к существующему хосту
3. Добавленные пользователи будут заметны в player_container - их можно будет заглушить и удалить из группы, а также заблокировать.
4. Все игроки в релизе будут иметь идентификатор - SteamID.
"""


func _on_host_btn_pressed() -> void:
	pass


func _on_client_btn_pressed() -> void:
	pass


func show_host_panel() -> void:
	animation_player.play("show-hide")


func hide_host_panel() -> void:
	animation_player.play_backwards("show-hide")
