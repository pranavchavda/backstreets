extends Node2D
## A building: flat roof, drop shadow, parapet outline, a few roof boxes.


var rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 1
	rng.seed = int(get_meta("seedv"))
	queue_redraw()


func _draw() -> void:
	var sizev: Vector2 = get_meta("size")
	var color: Color = get_meta("color")
	var r := Rect2(-sizev / 2.0, sizev)
	draw_rect(Rect2(r.position + Vector2(9, 11), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, color)
	draw_rect(r.grow(-2.5), color.darkened(0.45), false, 3.0)
	var boxes := 1 + rng.randi_range(0, 2)
	for _b in range(boxes):
		var bw := rng.randf_range(sizev.x * 0.1, sizev.x * 0.25)
		var bh := rng.randf_range(sizev.y * 0.1, sizev.y * 0.25)
		var bx := rng.randf_range(-sizev.x / 2.0 + bw, sizev.x / 2.0 - bw)
		var by := rng.randf_range(-sizev.y / 2.0 + bh, sizev.y / 2.0 - bh)
		draw_rect(Rect2(Vector2(bx - bw / 2.0, by - bh / 2.0), Vector2(bw, bh)), color.darkened(0.3))
	if get_meta("tower", false):
		draw_circle(Vector2.ZERO, 5.0, color.darkened(0.5))
		draw_circle(Vector2.ZERO, 2.0, Pal.ACCENT)
