extends Node

class_name DistanceCounter

func _levenshtein_distance(s: String, t: String) -> int:
	var n = s.length()
	var m = t.length()
	
	if n == 0:
		return m
	if m == 0:
		return n
	
	var d = []
	d.resize(n + 1)
	for i in range(n + 1):
		d[i] = []
		d[i].resize(m + 1)
		d[i][0] = i
	
	for j in range(m + 1):
		d[0][j] = j
	
	for i in range(1, n + 1):
		for j in range(1, m + 1):
			var cost = 0 if s[i - 1] == t[j - 1] else 1
			d[i][j] = min(
				d[i - 1][j] + 1,
				d[i][j - 1] + 1,
				d[i - 1][j - 1] + cost
			)
	
	return d[n][m]
