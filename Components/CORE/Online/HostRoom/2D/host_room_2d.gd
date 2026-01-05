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
1. Pressing the Host button - create a room with your IP, PORT, and a special code for connection. This step may require Port forwarding.
2. The Client button will ask for the data and try to connect to an existing host.
3. Added users will be visible in the player_container - they can be muted, removed from the group, and blocked.
4. All players in the release will have an identifier - SteamID or similar, to avoid duplicate connections.
"""


func _on_host_btn_pressed() -> void:
	pass


func _on_client_btn_pressed() -> void:
	pass


func show_host_panel() -> void:
	animation_player.play("show-hide")


func hide_host_panel() -> void:
	animation_player.play_backwards("show-hide")
