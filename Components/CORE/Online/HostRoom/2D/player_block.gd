extends Control

@onready var name_lbl = $HSplitContainer/WrapperLeft/NameLbl
@onready var pid_port_lbl = $"HSplitContainer/WrapperRight/PID-PortLbl"
@onready var bitrate_lbl = $HSplitContainer/WrapperRight/BitrateLbl
@onready var ping_lbl = $PingLbl
@onready var ext_btn = $ExtentionBtn

func _ready() -> void:
	pass
