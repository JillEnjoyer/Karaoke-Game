extends Control

@onready var animation_player = $AnimationPlayer

@onready var time_slider = $TimeSlider
@onready var slider = $TimeSlider/SliderPanel/HSlider
@onready var button = $TimeSlider/VisibilityPanel/Button
@onready var arrow_texture = $TimeSlider/VisibilityPanel/TextureRect
@onready var voice_channel_hbox = $Panel/Voice_Channel_HBox

@onready var hover_area = $Panel/HoverArea
@onready var hover_button = $Panel/HoverAppearBtn

signal h_slider_value_changed_signal(value)

var state = true
var hbox_position: bool = false

func _ready():
	slider.connect("value_changed", Callable(self, "on_h_slider_value_changed"))

func on_h_slider_value_changed(value: float) -> void:
	emit_signal("h_slider_value_changed_signal", value)

func _on_button_pressed() -> void:
	if state:
		animation_player.play("UP")
		arrow_texture.flip_v = true
	elif not state:
		animation_player.play_backwards("UP")
		arrow_texture.flip_v = false
	state = not state


func _on_hover_area_mouse_entered() -> void:
	await get_tree().create_timer(0.5).timeout
	hover_button.visible = true
func _on_hover_area_mouse_exited() -> void:
	if not hbox_position:
		await get_tree().create_timer(5).timeout
		hover_button.visible = false
func _on_hover_appear_btn_pressed() -> void:
	if hbox_position == false:
		hbox_position = true
		hover_area.visible = false
		animation_player.play("show_voice_channel")
	else:
		hbox_position = false
		hover_button.visible = false
		hover_area.visible = true
		animation_player.play_backwards("show_voice_channel")


func hide_timeslider() -> void:
	time_slider.visible = false
func show_timeslider() -> void:
	time_slider.visible = true
