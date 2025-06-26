extends Node
class_name AnimationHandler

## run_animation(animation_player: AnimationPlayer, anim_name: String, backwards: bool = false) -> Signal
func run_animation(animation_player: AnimationPlayer, anim_name: String, backwards: bool = false) -> Signal:
	if backwards:
		animation_player.play_backwards(anim_name)
	else:
		animation_player.play(anim_name)
	return animation_player.animation_finished
