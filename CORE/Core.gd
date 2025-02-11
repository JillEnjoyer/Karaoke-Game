extends Node

func _ready() -> void:
	var preferences_data = Node.new()
	preferences_data.name = "PreferencesData"
	preferences_data.set_script(load("res://Preferences/PreferencesData.gd"))
	add_child(preferences_data)

	var debugger = Node.new()
	debugger.name = "Debugger"
	debugger.set_script(load("res://Debug/Debugger.gd"))
	add_child(debugger)
	
	Core.get_node("Debugger").info("Core.gd", "_ready()", "PreferencesData и Debugger added!")
