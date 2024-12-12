"""
This debugger must import error/debug/info/exception notifications from whole project and put them into:
1. debug console environment
2. debug file that choosen by user (disabled if place is not choosen)

style must be:
FileName.gd->FunctionName(): --[STATUS]--|> MESSAGE
"""
extends Node

class logs:
	var debugger_active = false
	var msg_struct = "{FILE_NAME}->{METHOD_NAME}(): --[STATUS]--|> MESSAGE"
	
	func _init() -> void:
		debugger_active = PreferencesData.getData("debugger_enabled")
		
	func error(service_info, msg: String):
		if debugger_active:
			print()
