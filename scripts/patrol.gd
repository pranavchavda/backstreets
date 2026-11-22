extends CharacterBody2D
## Harbor police: seek the player, ram, reverse out when stuck, drive off when the heat drops.


var active := false
var leaving := false
var speed := 0.0
var stuck := 0.0
var rev := 0.0
var ram_cd := 0.0


func _ready() -> void:
	z_index = 1
	set_meta("game", get_tree().get_first_node_in_group("game"))
	queue_redraw()


func game():
	return get_meta("game")


func activate(g) -> void:
	set_meta("game", g)
	for _try in range(24):
		var along_road: bool = g.rng.randf() < 0.5
		var road: float = g.ROADS[g.rng.randi_range(0, 4)] * g.S
		var a: float = g.rng.randf_range(-760.0, 760.0)
		var p: Vector2 = Vector2(road, a) if along_road else Vector2(a, road)
		var d: float = p.distance_to(g.focus_pos())
		if d > 360.0 and d < 580.0:
			position = p
			rotation = (g.focus_pos() - p).angle()
			speed = 100.0
			active = true
			leaving = false
			visible = true
			return
	position = Vector2.ZERO
	speed = 100.0
	active = true
	leaving = false
	visible = true


func _physics_process(delta: float) -> void:
	var g = game()
	if not active or g.state != "playing":
		velocity = Vector2.ZERO
		return
	ram_cd -= delta
	var target: Vector2 = (position - g.focus_pos()) * 50.0 if leaving else g.focus_pos()
	var desired := (target - position).angle()
	var d := position.distance_to(g.focus_pos())
	if rev > 0:
		rev -= delta
		rotation = lerp_angle(rotation, desired + PI, 1.0 - exp(-2.0 * delta))
		velocity = Vector2.from_angle(rotation) * -60.0
	else:
		rotation = lerp_angle(rotation, desired, 1.0 - exp(-2.7 * delta))
		var top := 210.0 if d > 140.0 else (60.0 if d < 50.0 else 110.0)
		speed = minf(speed + 160.0 * delta, top)
		velocity = Vector2.from_angle(rotation) * speed
	var before := position
	move_and_slide()
	var moved := position.distance_to(before)
	if moved < velocity.length() * delta * 0.35 + 0.1:
		stuck += delta
	else:
		stuck = maxf(0.0, stuck - delta * 2.0)
	if stuck > 0.7 and rev <= 0:
		rev = 0.8
		stuck = 0.0
		speed = 0.0
	if d < 31.0 and ram_cd <= 0 and not leaving:
		ram_cd = 0.7
		g._shake = maxf(g._shake, 0.25)
		g._play_one_shot("thud")
		g.car.speed *= 0.8
		if g.driving:
			g.add_heat(0.1)
	if leaving and (absf(position.x) > 1200.0 or absf(position.y) > 1200.0):
		active = false
		visible = false
	queue_redraw()


func _draw() -> void:
	var g = game()
	Art.car(self, Pal.mix(Pal.ACCENT, 0.2), true, int(g.t_draw * 9.0) % 2 if g else 0)
