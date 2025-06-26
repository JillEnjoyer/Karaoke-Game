extends Control

@onready var TimeLbl = $TimeLbl
@onready var TimerNode = $Timer

var countdown_time = PreferencesData.getData("countdown_time")

signal ready_to_start

func _ready() -> void:
	TimerNode.wait_time = countdown_time
	TimerNode.one_shot = true
	TimerNode.connect("timeout", Callable(self, "_on_Timer_timeout"))
	TimerNode.start()
	TimeLbl.text = str(int(countdown_time))

func _process(delta: float) -> void:
	var remaining_time = TimerNode.time_left
	TimeLbl.text = str(int(remaining_time))


func _on_Timer_timeout() -> void:
	print("Timer finished, removing scene")
	self.queue_free()
	emit_signal("ready_to_start")
