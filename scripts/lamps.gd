extends Node2D
## Quay lamps: pole, glow, bright head. Statics are added by game.gd at the same spots.


func _ready() -> void:
	z_index = 2
	queue_redraw()


func _draw() -> void:
	for z in range(-800, 801, 200):
		if (z > -240 and z < -120) or (z > 300 and z < 580):
			continue
		draw_circle(Vector2(846, z), 7.0, Color(Pal.YELLOW.r, Pal.YELLOW.g, Pal.YELLOW.b, 0.14))
		draw_circle(Vector2(846, z), 2.2, Pal.YELLOW)
		draw_circle(Vector2(846, z), 1.1, Pal.rail())
