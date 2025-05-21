extends Node
class_name SubtitleMath


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return (1-t)*(1-t)*p0 + 2*(1-t)*t*p1 + t*t*p2
