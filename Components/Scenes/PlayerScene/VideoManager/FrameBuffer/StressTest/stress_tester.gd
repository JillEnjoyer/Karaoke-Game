extends Node
## Part of a Loading sequence

@onready var texture_rect = $TextureRect
@onready var text_label = $RichTextLabel

var results: Array = []
var texture: Texture = null

var color: Color = "green"

## It would import (video_players and jumper array)
## Using preloaded files right away we would check its speed
func stress_test_config(video_names: Array, video_players: Dictionary, jumpers: Array) -> void:
	for video_name in video_names:
		Debugger.info("Starting stress test for: " + video_name)
		var video_player = video_players[video_name]

		for jumper in jumpers:
			# only media "jumps" interest us (seek's)
			if jumper.has("from_time") and jumper.has("to_time") and jumper.get("id", "") == video_name:
				await _measure_seek(video_player, jumper["to_time"])

	_finish_test()

## 1 seek measurement
func _measure_seek(video_player: VideoController, target_time: float) -> void:
	var start_ticks = Time.get_ticks_msec()

	var image = video_player.seek(target_time)
	if image:
		if not texture:
			texture = ImageTexture.create_from_image(image)
			texture_rect.texture = texture
		else:
			texture.update(image)
	
	await get_tree().process_frame

	var delta = Time.get_ticks_msec() - start_ticks
	results.append({
		"target_time": target_time,
		"seek_and_display_ms": delta
	})

	if delta > 50: color = "yellow"
	if delta > 150: color = "red"

	text_label.append_text("[color=%s]Seek to %.2f - %d ms[/color]\n" % [color, target_time, delta])
	Debugger.debug("Seek to %.2f: %d ms" % [target_time, delta])

	await get_tree().create_timer(0.5).timeout


func _finish_test() -> void:
	var total_time = 0
	var max_time = 0
	for res in results:
		total_time += res["seek_and_display_ms"]
		max_time = max(max_time, res["seek_and_display_ms"])
	
	var avg: float = total_time / results.size() if results.size() > 0 else 0
	Debugger.info("Test Done! Avg: %.1f ms, Max: %d ms" % [avg, max_time])