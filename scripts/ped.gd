extends CharacterBody2D
## Pedestrians walk plot perimeters, flee the player's car, and get knocked down.


var corner := 0
var dir_sign := 1
var flee := 0.0
var flee_dir := Vector2.ZERO
var fall := 0.0
var is_courier := false
var color := Pal.MUTED
var plot: Rect2


func _ready() -> void:
	z_index = 1
	var game = get_tree().get_first_node_in_group("game")
	set_meta("game", game)
	plot = get_meta("plot")
	color = get_meta("color")
	is_courier = get_meta("courier", false)
	queue_redraw()


func game():
	return get_meta("game")


func corner_pos(idx: int) -> Vector2:
	var xs := [plot.position.x, plot.position.x + plot.size.x]
	var zs := [plot.position.y, plot.position.y + plot.size.y]
	return Vector2(xs[idx & 1], zs[idx >> 1 & 1])


func reset(g) -> void:
	if is_courier:
		position = g.COURIER * g.S
		visible = true
		return
	var c: Vector2 = corner_pos(corner)
	position = c + Vector2(g.rng.randf_range(-10, 10), g.rng.randf_range(-10, 10))
	fall = 0.0
	flee = 0.0
	visible = true


func _physics_process(delta: float) -> void:
	var g = game()
	if g.state != "playing":
		return
	if is_courier:
		if g.courier_state == "leaving":
			position.x -= 22.0 * delta
			rotation = PI
			if position.x < 760.0:
				g.courier_state = "gone"
				visible = false
		queue_redraw()
		return
	if fall > 0:
		fall -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return
	var car_near: float = g.car.position.distance_squared_to(position) if g.driving else 1e9
	if g.driving and absf(g.car.speed) > 50.0 and car_near < 150.0:
		fall = 2.8
		g.add_heat(0.95)
		g._play_one_shot("thud")
		g._shake = 0.35
		g.car.speed *= 0.85
		return
	if flee > 0:
		flee -= delta
		velocity = flee_dir * 64.0
		rotation = flee_dir.angle()
	else:
		if g.driving and absf(g.car.speed) > 80.0 and car_near < 6400.0:
			flee = 1.1
			flee_dir = (position - g.car.position).normalized()
		var t := corner_pos(corner)
		var d := t - position
		if d.length() < 4.0:
			corner = (corner + dir_sign + 4) % 4
			if g.rng.randf() < 0.12:
				dir_sign *= -1
			velocity = Vector2.ZERO
		else:
			velocity = d.normalized() * 17.0
			rotation = d.angle()
	move_and_slide()
	queue_redraw()


func _draw() -> void:
	if fall > 0:
		draw_set_transform(Vector2.ZERO, rotation, Vector2(1.4, 0.45))
	Art.ped(self, color, is_courier)
