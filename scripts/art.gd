class_name Art
## Shared vector drawing: cars, people, the case, HUD stars. Front of a car is +x.


static func car(c: CanvasItem, color: Color, patrol: bool, lamp_phase: int) -> void:
	c.draw_rect(Rect2(-19, -10, 38, 20), color)
	c.draw_rect(Rect2(-10, -8.5, 20, 17), color.darkened(0.3))
	c.draw_rect(Rect2(4, -8.6, 4, 17.2), Pal.mix(Pal.BG, 0.25, Color.BLACK))
	for w in [Vector2(-13, -10.5), Vector2(13, -10.5), Vector2(-13, 10.5), Vector2(13, 10.5)]:
		c.draw_rect(Rect2(w.x - 2, w.y - 3, 4, 6), Pal.mix(Pal.BG, 0.45, Color.BLACK))
	c.draw_circle(Vector2(17, -6), 1.6, Pal.mix(Pal.YELLOW, 0.1, Color.WHITE))
	c.draw_circle(Vector2(17, 6), 1.6, Pal.mix(Pal.YELLOW, 0.1, Color.WHITE))
	c.draw_rect(Rect2(-19.4, -7, 1.6, 14), Pal.RED)
	if patrol:
		c.draw_circle(Vector2(-4, -3.4), 2.2, Pal.RED if lamp_phase == 0 else Pal.RED.darkened(0.85))
		c.draw_circle(Vector2(-4, 3.4), 2.2, Pal.CYAN if lamp_phase == 1 else Pal.CYAN.darkened(0.85))


static func ped(c: CanvasItem, color: Color, courier: bool) -> void:
	c.draw_circle(Vector2.ZERO, 4.6, color)
	c.draw_circle(Vector2(1.2, 0), 2.3, Pal.mix(Pal.ORANGE, 0.35, Color.WHITE))
	if courier:
		c.draw_rect(Rect2(-4.6, -1.2, 9.2, 2.4), Pal.YELLOW)


static func case_art(c: CanvasItem) -> void:
	c.draw_rect(Rect2(-3.1, -2.1, 6.2, 4.2), Pal.mix(Pal.ORANGE, 0.35, Color.BLACK))
	c.draw_rect(Rect2(-1.0, -2.5, 2.0, 0.9), Pal.mix(Pal.ORANGE, 0.1, Color.BLACK))


static func star_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(10):
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	return pts
