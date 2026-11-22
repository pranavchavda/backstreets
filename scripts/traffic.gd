extends Node2D
## Traffic: cars hop node to node along the road grid on bezier legs,
## right-hand lane offset, braking for whatever is ahead of them.


var i := 0
var j := 0
var di := 1
var dj := 0
var from := Vector2.ZERO
var ctrl := Vector2.ZERO
var to := Vector2.ZERO
var len := 10.0
var seg := 0.0
var speed := 0.0
var hit_cd := 0.0
var honk_cd := 0.0
var stun := 0.0
var spin := 0.0
var color := Pal.MUTED


func _ready() -> void:
	z_index = 1
	var game = get_tree().get_first_node_in_group("game")
	set_meta("game", game)
	color = Pal.tints()[game.rng.randi_range(0, 4)].lerp(Pal.walkc(), 0.15)
	queue_redraw()


func game():
	return get_meta("game")


func respawn(g) -> void:
	set_meta("game", g)
	for _try in range(20):
		i = g.rng.randi_range(0, 4)
		j = g.rng.randi_range(0, 4)
		var d: float = Vector2(g.ROADS[i], g.ROADS[j]).distance_to(g.focus_pos() / g.S)
		if d > 40 and d < 95:
			pick_leg(true)
			speed = 85.0
			stun = 0.0
			spin = 0.0
			position = bezier(0.0)
			rotation = tangent().angle()
			return


func pick_leg(first: bool) -> void:
	var g = game()
	var options: Array = []
	if i > 0:
		options.append([-1, 0])
	if i < 4:
		options.append([1, 0])
	if j > 0:
		options.append([0, -1])
	if j < 4:
		options.append([0, 1])
	var back: Array = options.filter(func(o): return not (not first and o[0] == -di and o[1] == -dj))
	var straight = null
	for o in back:
		if o[0] == di and o[1] == dj:
			straight = o
			break
	var pick = straight if straight != null and g.rng.randf() < 0.55 else back[g.rng.randi_range(0, back.size() - 1)]
	di = pick[0]
	dj = pick[1]
	var rx := -dj * 25.0
	var rz := di * 25.0
	var ax: float = g.ROADS[i] * g.S
	var az: float = g.ROADS[j] * g.S
	var bx: float = g.ROADS[i + di] * g.S
	var bz: float = g.ROADS[j + dj] * g.S
	from = Vector2(ax + rx, az + rz)
	to = Vector2(bx + rx, bz + rz)
	ctrl = Vector2(bx + rx * 1.35, az + rz * 1.35) if di != 0 else Vector2(ax + rx * 1.35, bz + rz * 1.35)
	len = from.distance_to(ctrl) + ctrl.distance_to(to)
	seg = 0.0


func bezier(t: float) -> Vector2:
	var u := 1.0 - t
	return Vector2(
		u * u * from.x + 2 * u * t * ctrl.x + t * t * to.x,
		u * u * from.y + 2 * u * t * ctrl.y + t * t * to.y)


func tangent() -> Vector2:
	var u := 1.0 - seg
	return Vector2(
		2 * u * (ctrl.x - from.x) + 2 * seg * (to.x - ctrl.x),
		2 * u * (ctrl.y - from.y) + 2 * seg * (to.y - ctrl.y)).normalized()


func _physics_process(delta: float) -> void:
	var g = game()
	if g.state != "playing":
		return
	hit_cd -= delta
	honk_cd -= delta
	if stun > 0:
		stun -= delta
		rotation += spin * delta
		spin *= maxf(0.0, 1.0 - 1.5 * delta)
		return
	var ahead := position + tangent() * 55.0
	var blocked := ahead.distance_squared_to(g.focus_pos()) < 110.0
	if not blocked:
		for o in g.traffic:
			if o != self and o.stun <= 0 and ahead.distance_squared_to(o.position) < 80.0:
				blocked = true
				break
	speed = lerpf(speed, 0.0 if blocked else 85.0, 1.0 - exp(-4.0 * delta))
	if blocked and honk_cd <= 0 and position.distance_squared_to(g.focus_pos()) < 640.0:
		g._play_one_shot("honk")
		honk_cd = 2.0 + g.rng.randf() * 3.0
	seg += speed * delta / maxf(len, 40.0)
	if seg >= 1.0:
		i += di
		j += dj
		pick_leg(false)
	position = bezier(seg)
	rotation = tangent().angle()
	if position.distance_squared_to(g.focus_pos()) > 1300.0 * 1300.0:
		respawn(g)
	queue_redraw()


func _draw() -> void:
	Art.car(self, color, false, 0)
