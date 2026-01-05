extends SubViewport

@onready var viewport_base = $"../../../ViewportBase"

func show_node(state: bool) -> void:
	## 1. turn off all capturing if off and on if on
	## 2. hide viewport
	
	viewport_base.visible = state
