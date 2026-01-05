extends Control

## Signals
signal step_change_requested(step)

## Objects on the scene

@onready var swipe_hint_lbl = $Panel/ActionPanel/SwipeControl/HintLbl

@onready var option_button = $Panel/FASChoser/OptionButton
@onready var show_add_new_btn = $Panel/FASChoser/ShowAddNewBtn
@onready var group_create_lbl = $Panel/FASChoser/GroupCreaterLbl
@onready var option_button_two = $Panel/FASChoser/OptionButton2
@onready var add_new_btn = $Panel/FASChoser/AddNewBtn

func _ready() -> void:
	pass


## 1. FAS
func _on_show_add_new_btn_pressed() -> void:
	show_add_new_btn.visible = false

	group_create_lbl.visible = true
	option_button_two.visible = true
	add_new_btn.visible = true

func _on_add_new_btn_pressed() -> void:
	show_add_new_btn.visible = true

	group_create_lbl.visible = false
	option_button_two.visible = false
	add_new_btn.visible = false

## 3. Previous/Next Step
func _on_previous_step_btn_pressed() -> void:
	emit_signal("step_change_requested", -1)
func _on_next_btn_pressed() -> void:
	emit_signal("step_change_requested", 1)


## Swipe object
var swipe_pressed := false
func _on_swipe_control_pressed() -> void:
	swipe_pressed = true


func _on_swipe_control_mouse_entered() -> void:
	swipe_hint_lbl.visible = false
func _on_swipe_control_mouse_exited() -> void:
	swipe_hint_lbl.visible = true
