#popup.gd
extends Control
signal popup_closed

@onready var label = $Label
@onready var button = $Label/Button

func _ready() -> void:
	self.visible = false
	button.pressed.connect(_on_texture_button_pressed)

func set_info(text: String, btn_text: String) -> void:
	self.visible = true
	label.text = text
	button.text = btn_text

func _on_texture_button_pressed() -> void:
	self.visible = false
	emit_signal("popup_closed")

func wait_for_close() -> void:
	await self.popup_closed
