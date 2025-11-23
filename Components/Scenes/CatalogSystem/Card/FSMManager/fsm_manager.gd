extends Node

class_name FSMManager

var animation_handler := AnimationHandler.new()

var animation_player: AnimationPlayer
var previous_state: String
var current_state: String
var transition_table: Dictionary
var is_processing := false
var input_buffer: Array = []


func setup(anim_player: AnimationPlayer, initial_state: String, transitions: Dictionary):
	animation_player = anim_player
	current_state = initial_state
	transition_table = transitions


func handle_input(command: String):
	input_buffer.append(command)
	_process_next()


func _process_next():
	if is_processing or input_buffer.is_empty():
		return

	is_processing = true
	var command = input_buffer.pop_front()
	await _apply_transition(command)
	is_processing = false
	_process_next()


func _apply_transition(command: String) -> void:
	var state_transitions = transition_table.get(current_state, {})
	if not state_transitions.has(command):
		Debugger.warning("No transition from '%s' with input '%s'" % [current_state, command])
		return

	var transition = state_transitions[command]
	var animations: Array = transition.get("animations", [])
	var next_state: String = transition.get("next_state", current_state)

	for anim in animations:
		var name: String = anim.get("name", "")
		var reverse: bool = anim.get("reverse", false)
		if name != "":
			await animation_handler.run_animation(animation_player, name, reverse)

	previous_state = current_state
	current_state = next_state
	Debugger.debug("FSM transition: %s -> %s" % [previous_state, current_state])
