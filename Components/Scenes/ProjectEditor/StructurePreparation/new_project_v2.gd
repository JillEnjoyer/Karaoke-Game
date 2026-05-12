extends Control

@onready var project_panel = UIManager.get_desired_node("NewProjectPanel")

enum LEVELS {
	FRANCHISE,
	ALBUM,
	SONG
}

var current_state = LEVELS.FRANCHISE


func _ready() -> void:
	var end := false
	while not end:
		var panel = show_panel()
		var step = await panel.panel_closed # panel_closed should be
		remove_child(panel)
		panel.queue_free()
		current_state += step
		if current_state < LEVELS.FRANCHISE or current_state > LEVELS.SONG:
			end = true
	
	Debugger.info("New Project Popup should be closed")
		

func show_panel() -> Object:
	project_panel.instantiate()
	project_panel.setup_panel(current_state)
	project_panel.connect("step_change_requested", Callable(self, ""))
	add_child(project_panel)
	return project_panel

func switch_level(next: int = 1):
	current_state += next
