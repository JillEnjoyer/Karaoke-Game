extends Node
class_name TweenController

var tween: Tween

func ensure_tween_ready():
	if tween == null:
		tween = create_tween()


func animate_property(
	target: Object,
	property: String,
	start_value = null,
	final_value = 0,
	duration := 0.5,
	transition_type := Tween.TRANS_LINEAR,
	ease_type := Tween.EASE_IN_OUT
) -> void:
	if tween.is_running():
		tween.kill()
	tween = create_tween()

	if start_value == null:
		start_value = target.get(property)
	
	target.set(property, start_value)

	var tween_step = tween.tween_property(target, property, final_value, duration)
	tween_step.set_trans(transition_type)
	tween_step.set_ease(ease_type)

	await tween.finished



# "Парабола" (примерно правая ветвь x^2) — резко ускоряется, потом замедляется
func animate_parabolic(target: Object, property: String, from_value: float, to_value: float, duration:float = 1.0):
	await animate_property(
		target,
		property,
		from_value,
		to_value,
		duration,
		Tween.TRANS_QUAD,
		Tween.EASE_OUT  # имитирует параболическую правую часть
	)

# "Круговая" синусоидальная кривая туда-обратно
func animate_sine_loop(target: Object, property: String, amplitude: float, base_value: float, duration := 1.0):
	# x -> x + amplitude
	await animate_property(
		target,
		property,
		base_value + amplitude,  # final_value
		base_value,             # start_value
		duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
	# x + amplitude -> x
	await animate_property(
		target,
		property,
		base_value,             # final_value
		base_value + amplitude, # start_value
		duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)
