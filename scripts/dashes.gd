extends Node2D
## Centre-line dashes down every road, skipping intersections. Drawn once.


func _ready() -> void:
	z_index = -4
	queue_redraw()


func _draw() -> void:
	var color := Pal.mix(Pal.YELLOW, 0.05, Color.WHITE)
	var roads := [-720.0, -360.0, 0.0, 360.0, 720.0]
	for r in roads:
		for a in range(-760, 761, 40):
			var skip := false
			for c in roads:
				if absf(a - c) < 70.0:
					skip = true
					break
			if skip:
				continue
			draw_rect(Rect2(r - 1.4, a - 8.5, 2.8, 17.0), color)
			draw_rect(Rect2(a - 8.5, r - 1.4, 17.0, 2.8), color)
