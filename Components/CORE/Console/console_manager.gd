# ConsoleManager.gd (Autoload)
extends Node

var expression = Expression.new()


func execute_command(command_str: String, context_node: Object):
	# command_str: "get_node('Timeline').get_child(0).size.x = 500"
	
	var error = expression.parse(command_str)
	if error != OK:
		print("Error parsing command: ", expression.get_error_text())
		return

	var result = expression.execute([], context_node)
	
	if not expression.has_execute_failed():
		print("Command Executed. Result: ", result)
	else:
		print("Execution failed: ", expression.get_error_text())

# Use in EditorScene:
# ConsoleManager.execute_command("timeline.get_child(0).segments[0].size", self)
