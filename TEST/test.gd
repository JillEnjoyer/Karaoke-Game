extends Node

var player: AudioStreamPlayer
var slow_factor := 0.5
var test_interval := 1.0

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)

	var stream = load("res://test.mp3")
	player.stream = stream

	player.pitch_scale = 1.0 / slow_factor

	player.play()

	seek_loop()
	

func seek_loop() -> void:
	while true:
		var duration = player.stream.get_length()

		var t = randf() * (duration - 0.1)
		
		var start_time := Time.get_ticks_usec()
		player.seek(t)

		Debugger.debug("Seek to: ", t)
		
		var end_time := Time.get_ticks_usec()
		Debugger.debug(str((end_time - start_time)/1000.0) + "ms")

		await get_tree().create_timer(test_interval).timeout
