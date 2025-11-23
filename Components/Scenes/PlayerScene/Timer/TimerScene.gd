extends Control

signal ready_to_start

@onready var timeLbl = $TimeLbl
@onready var timerNode = $Timer

var countdown_time = PreferencesData.get_data("countdown_time")


func _ready() -> void:
	timerNode.wait_time = countdown_time
	timerNode.one_shot = true
	timerNode.connect("timeout", Callable(self, "_on_timer_timeout"))
	timerNode.start()
	timeLbl.text = str(int(countdown_time))


func _process(delta: float) -> void:
	var remaining_time = timerNode.time_left
	timeLbl.text = str(int(remaining_time))


func _on_timer_timeout() -> void:
	self.queue_free()
	emit_signal("ready_to_start")
