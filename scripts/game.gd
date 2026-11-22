extends Node2D
## Backstreets, Chapter 1: The Handoff — Godot port of the Game Vibes original.
## World units match the HTML version; S converts to pixels.


const S := 10.0
const ROADS: Array[float] = [-72.0, -36.0, 0.0, 36.0, 72.0]
const CAR_START := Vector2(-74.5, 12.0)
const COURIER := Vector2(100.0, -18.0)
const DELIVER := Vector2(78.4, 45.0)
const PLAYER_START := Vector2(-58.0, 6.5)

const OBJECTIVES := [
	{"text": "Reach your car", "at": CAR_START},
	{"text": "Meet the courier at Pier 7", "at": COURIER},
	{"text": "Deliver the case — ferry terminal", "at": DELIVER},
]

const WALK_SPEED := 64.0

var rng := RandomNumberGenerator.new()
var state := "title"          # title, story, playing, paused, over
var score := 0.0
var best: float = -1.0
var muted := false

var objective := 0
var heat := 0.0
var bust_t := 0.0
var has_case := false
var driving := false
var focus_speed := 0.0
var focus_vel := Vector2.ZERO
var flash_until := -1.0
var t_draw := 0.0
var shown_stars := 0
var courier_state := "waiting"
var _shake := 0.0

var player
var car
var case_sprite: Node2D
var courier
var beacon: Node2D
var arrow: Node2D
var boat: Node2D
var cam: Camera2D
var hud
var story
var screens
var traffic: Array = []
var peds: Array = []
var patrols: Array = []
var ped_plots: Array = []

var snd := {}
var engine_player: AudioStreamPlayer
var siren_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game")
	rng.seed = 1
	_load_save()
	_setup_input()
	_setup_audio()
	_build_world()
	_spawn_actors()
	cam = Camera2D.new()
	cam.zoom = Vector2(1.55, 1.55)
	add_child(cam)
	cam.make_current()
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	screens = preload("res://scripts/screens.gd").new()
	add_child(screens)
	story = preload("res://scripts/story.gd").new()
	add_child(story)
	reset_round()
	screens.show_title()


func _setup_input() -> void:
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("action", [KEY_SPACE, KEY_ENTER])
	_add_action("pause", [KEY_ESCAPE, KEY_P])
	_add_action("leave", [KEY_Q])
	_add_action("mute", [KEY_M])
	if not InputMap.has_action("horn"):
		InputMap.add_action("horn")
		var horn := InputEventMouseButton.new()
		horn.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("horn", horn)


func _add_action(name: String, keys: Array) -> void:
	if InputMap.has_action(name):
		return
	InputMap.add_action(name)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(name, e)


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		best = cfg.get_value("save", "best", -1.0)
		muted = cfg.get_value("save", "muted", false)
	AudioServer.set_bus_mute(0, muted)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "best", best)
	cfg.set_value("save", "muted", muted)
	cfg.set_value("save", "chapter", 1)
	cfg.save("user://save.cfg")


func set_seed(n: int) -> void:
	rng.seed = n


# ---------------------------------------------------------------------------
# World
# ---------------------------------------------------------------------------

func _rect(parent: Node, cx: float, cy: float, w: float, h: float, color: Color, z: int = 0) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(w, h)
	r.position = Vector2(cx - w / 2.0, cy - h / 2.0)
	r.z_index = z
	parent.add_child(r)
	return r


func _static_rect(cx: float, cy: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	body.position = Vector2(cx, cy)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _static_circle(cx: float, cy: float, r: float) -> void:
	var body := StaticBody2D.new()
	var shape := CircleShape2D.new()
	shape.radius = r
	body.position = Vector2(cx, cy)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _build_world() -> void:
	_rect(self, 0, 0, 8000, 8000, Pal.edge(), -12)
	_rect(self, 2660, 0, 3600, 3000, Pal.water(), -11)
	_rect(self, 0, 0, 1840, 1840, Pal.road(), -10)
	_rect(self, 817.5, 0, 95, 1800, Pal.quay(), -5)
	_rect(self, 905, -180, 270, 60, Pal.quay(), -5)

	var dashes := preload("res://scripts/dashes.gd").new()
	add_child(dashes)

	var special := {"1,1": "plaza", "2,1": "park", "2,2": "tower", "1,2": "market"}
	for i in range(4):
		for j in range(4):
			var cx := (ROADS[i] + ROADS[i + 1]) / 2.0 * S
			var cz := (ROADS[j] + ROADS[j + 1]) / 2.0 * S
			var kind: String = special.get("%d,%d" % [i, j], "blocks")
			ped_plots.append(Rect2(cx - 116, cz - 116, 232, 232))
			_rect(self, cx, cz, 274, 274, Pal.grass() if kind == "park" else Pal.walkc(), -5)
			if kind == "plaza":
				_rect(self, cx, cz, 64, 64, Pal.quay(), 0)
				_rect(self, cx, cz, 52, 52, Pal.water(), 1)
				_rect(self, cx, cz, 9, 60, Pal.quay(), 2)
				_rect(self, cx, cz, 60, 9, Pal.quay(), 2)
				_static_circle(cx, cz, 35.0)
			elif kind == "park":
				for _t in range(7):
					var tx := cx + rng.randf_range(-90, 90)
					var tz := cz + rng.randf_range(-90, 90)
					_rect(self, tx, tz, 4, 4, Pal.mix(Pal.ORANGE, 0.55, Color.BLACK), 1)
					_rect(self, tx, tz, 27, 27, Pal.mix(Pal.GREEN, 0.25, Color.BLACK), 2)
					_static_circle(tx, tz, 5.5)
			elif kind == "tower":
				_add_building(cx, cz, 160.0, 160.0, Pal.mix(Pal.ACCENT, 0.25), true)
			elif kind == "market":
				for off in [Vector2(-70, -70), Vector2(70, -70), Vector2(-70, 70), Vector2(70, 70)]:
					_add_building(cx + off.x, cz + off.y, 60, 60, Pal.tints()[rng.randi_range(0, 4)], false)
			else:
				for qi in range(2):
					for qj in range(2):
						if rng.randf() >= 0.78:
							continue
						var w := (7.0 + rng.randf() * 5.0) * S
						var d := (7.0 + rng.randf() * 5.0) * S
						var bx := cx + (1.0 if qi == 1 else -1.0) * (48.0 + rng.randf() * 22.0)
						var bz := cz + (1.0 if qj == 1 else -1.0) * (48.0 + rng.randf() * 22.0)
						_add_building(bx, bz, w, d, Pal.tints()[rng.randi_range(0, 4)].lerp(Pal.walkc(), rng.randf() * 0.25), false)

	_add_building(-540, 180, 100, 70, Pal.mix(Pal.RED, 0.25), false)
	_rect(self, -593, 180, 3.5, 54, Pal.ACCENT, 2)

	_add_building(840, 450, 70, 210, Pal.mix(Pal.ACCENT, 0.3), false)
	_rect(self, 804.5, 450, 3, 26, Pal.YELLOW, 2)

	boat = preload("res://scripts/boat.gd").new()
	boat.position = Vector2(1000, -250)
	add_child(boat)

	_rail(862, -557.5, 8, 343)
	_rail(862, 97.5, 8, 242)
	_rail(862, 730, 8, 340)
	_rail(905, -213, 273, 8)
	_rail(905, -147, 273, 8)
	_rail(1043, -180, 8, 68)
	for z in [-204.0, -180.0, -156.0]:
		_rect(self, 786, z, 6, 6, Pal.rail(), 1)
		_static_circle(786, z, 4.5)

	var lamps := preload("res://scripts/lamps.gd").new()
	add_child(lamps)
	for z in range(-800, 801, 200):
		if (z > -240 and z < -120) or (z > 300 and z < 580):
			continue
		_static_circle(846, z, 1.8)

	for spot in [[-500.0, -820.0, 300.0, 100.0], [0.0, -820.0, 260.0, 100.0], [500.0, -820.0, 300.0, 100.0], [-820.0, -400.0, 100.0, 280.0], [-820.0, 400.0, 100.0, 280.0]]:
		_add_building(spot[0], spot[1], spot[2], spot[3], Pal.mix(Pal.MUTED, 0.35), false)
	var crate_colors := [Pal.RED, Pal.ORANGE, Pal.MAGENTA, Pal.GREEN, Pal.ACCENT]
	for x in range(-62, 63, 7):
		for row in range(2):
			if rng.randf() < 0.3:
				continue
			_rect(self, x * S, 815 + row * 32, 56, 23, Pal.mix(crate_colors[rng.randi_range(0, 4)], 0.25), 0)
	_static_rect(0, 838, 1320, 82)

	var parked_colors := [Pal.mix(Pal.MUTED, 0.1), Pal.mix(Pal.MAGENTA, 0.45), Pal.mix(Pal.GREEN, 0.5), Pal.mix(Pal.ACCENT, 0.35), Pal.mix(Pal.ORANGE, 0.4)]
	var parked_spots := [[-320.0, -500.0, 0.0], [-400.0, 260.0, 180.0], [300.0, -320.0, 90.0], [-140.0, 400.0, 270.0], [40.0, -40.0, 0.0], [400.0, 220.0, 180.0], [-685.0, -300.0, 90.0], [220.0, 685.0, 270.0], [-540.0, -685.0, 90.0], [685.0, -60.0, 90.0]]
	for i in range(parked_spots.size()):
		var p := Node2D.new()
		p.set_script(preload("res://scripts/parked.gd"))
		p.position = Vector2(parked_spots[i][0], parked_spots[i][1])
		p.rotation_degrees = parked_spots[i][2]
		p.set_meta("color", parked_colors[i % parked_colors.size()])
		add_child(p)
		var horizontal: bool = parked_spots[i][2] == 0.0 or parked_spots[i][2] == 180.0
		if horizontal:
			_static_rect(parked_spots[i][0], parked_spots[i][1], 42, 22)
		else:
			_static_rect(parked_spots[i][0], parked_spots[i][1], 22, 42)

	_static_rect(-900, 0, 40, 1900)
	_static_rect(1060, 0, 40, 1900)
	_static_rect(0, -900, 2100, 40)
	_static_rect(0, 900, 2100, 40)


func _rail(cx: float, cy: float, w: float, h: float) -> void:
	_rect(self, cx, cy, w, h, Pal.rail(), 1)
	_static_rect(cx, cy, w + 6, h + 6)


func _add_building(cx: float, cz: float, w: float, d: float, color: Color, tower: bool) -> void:
	var b := Node2D.new()
	b.set_script(preload("res://scripts/building.gd"))
	b.position = Vector2(cx, cz)
	b.set_meta("size", Vector2(w, d))
	b.set_meta("color", color)
	b.set_meta("tower", tower)
	b.set_meta("seedv", rng.randi())
	add_child(b)
	_static_rect(cx, cz, w, d)


# ---------------------------------------------------------------------------
# Actors
# ---------------------------------------------------------------------------

func _spawn_actors() -> void:
	player = CharacterBody2D.new()
	player.set_script(preload("res://scripts/player.gd"))
	_body(player, 5.0)
	add_child(player)

	car = CharacterBody2D.new()
	car.set_script(preload("res://scripts/car.gd"))
	_body(car, 13.5)
	add_child(car)

	case_sprite = Node2D.new()
	case_sprite.set_script(preload("res://scripts/case.gd"))
	add_child(case_sprite)

	for i in range(12):
		var t := Node2D.new()
		t.set_script(preload("res://scripts/traffic.gd"))
		add_child(t)
		traffic.append(t)

	ped_plots.append(Rect2(785, -700, 65, 1400))
	ped_plots.append(Rect2(790, -196, 240, 32))
	var ped_colors := [Pal.mix(Pal.MUTED, 0.2), Pal.mix(Pal.GREEN, 0.55), Pal.mix(Pal.MAGENTA, 0.6), Pal.mix(Pal.ORANGE, 0.5), Pal.mix(Pal.FG, 0.4), Pal.mix(Pal.RED, 0.5)]
	for i in range(15):
		var p := CharacterBody2D.new()
		p.set_script(preload("res://scripts/ped.gd"))
		_body(p, 4.0)
		p.set_meta("plot", ped_plots[i % ped_plots.size()])
		p.set_meta("color", ped_colors[i % ped_colors.size()])
		add_child(p)
		peds.append(p)

	courier = CharacterBody2D.new()
	courier.set_script(preload("res://scripts/ped.gd"))
	_body(courier, 4.0)
	courier.set_meta("plot", Rect2(790, -196, 240, 32))
	courier.set_meta("color", Pal.mix(Pal.YELLOW, 0.1, Color.WHITE))
	courier.set_meta("courier", true)
	add_child(courier)

	for i in range(3):
		var p := CharacterBody2D.new()
		p.set_script(preload("res://scripts/patrol.gd"))
		_body(p, 13.5)
		add_child(p)
		patrols.append(p)

	beacon = Node2D.new()
	beacon.set_script(preload("res://scripts/beacon.gd"))
	add_child(beacon)
	arrow = Node2D.new()
	arrow.set_script(preload("res://scripts/arrow.gd"))
	add_child(arrow)


func _body(n: CharacterBody2D, r: float) -> void:
	n.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CircleShape2D.new()
	shape.radius = r
	var cs := CollisionShape2D.new()
	cs.shape = shape
	n.add_child(cs)


# ---------------------------------------------------------------------------
# Round flow
# ---------------------------------------------------------------------------

func reset_round() -> void:
	score = 0.0
	objective = 0
	heat = 0.0
	bust_t = 0.0
	has_case = false
	driving = false
	courier_state = "waiting"
	flash_until = -1.0
	focus_vel = Vector2.ZERO
	focus_speed = 0.0
	shown_stars = 0
	_shake = 0.0
	player.visible = true
	player.position = PLAYER_START * S
	player.rotation = (CAR_START * S - player.position).angle()
	car.position = CAR_START * S
	car.rotation = -PI / 2
	car.speed = 0.0
	courier.visible = true
	courier.position = COURIER * S
	case_sprite.reparent(self)
	case_sprite.position = COURIER * S + Vector2(7, 3)
	case_sprite.rotation = 0.4
	set_objective(0)
	for t in traffic:
		t.respawn(self)
	for p in peds:
		p.reset(self)
	for p in patrols:
		p.active = false
		p.leaving = false
		p.visible = false
		p.speed = 0.0
	if engine_player:
		engine_player.stop()
	if siren_player:
		siren_player.stop()
	screens.hint("")
	cam.position = player.position
	cam.force_update_scroll()


func start_round() -> void:
	reset_round()
	state = "playing"
	get_tree().paused = false
	screens.hide_all()
	screens.hint("")


func apply_debug(kind: String) -> void:
	if kind == "drive":
		player.position = Vector2(-725, 100)
	elif kind == "bust":
		heat = 2.9
		bust_t = 1.0
		var p: CharacterBody2D = patrols[0]
		p.active = true
		p.visible = true
		p.position = Vector2(-560, 80)
	elif kind == "win":
		player.position = Vector2(765, 450)
		has_case = true
		set_objective(2)


func set_objective(n: int) -> void:
	objective = n
	beacon.position = OBJECTIVES[n]["at"] * S
	_play_one_shot("blip")


func end_round(won: bool, title: String, detail: String) -> void:
	if state != "playing":
		return
	if won and (best < 0 or score < best):
		best = score
	if won:
		_play_one_shot("win")
		_save()
	if engine_player:
		engine_player.stop()
	if siren_player:
		siren_player.stop()
	state = "over"
	screens.hint("")
	screens.show_over(won, title, detail, best)


func _physics_process(delta: float) -> void:
	if state == "playing":
		_round_step(delta)
	elif state == "over":
		if Input.is_action_just_pressed("action"):
			start_round()
	elif state == "title":
		if Input.is_action_just_pressed("action"):
			state = "story"
			story.open(self)
		elif Input.is_action_just_pressed("pause"):
			_save()
			get_tree().quit()
	elif state == "paused":
		if Input.is_action_just_pressed("pause"):
			state = "playing"
			get_tree().paused = false
			screens.hide_pause()
		elif Input.is_action_just_pressed("leave"):
			_save()
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if state == "playing" and event.is_action_pressed("pause"):
		state = "paused"
		get_tree().paused = true
		screens.show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("mute"):
		muted = !muted
		AudioServer.set_bus_mute(0, muted)
		_save()


func _round_step(delta: float) -> void:
	score += delta
	var act := Input.is_action_just_pressed("action")
	if not driving:
		var d_car: float = player.position.distance_to(car.position)
		var d_courier: float = player.position.distance_to(COURIER * S)
		var d_deliver: float = player.position.distance_to(DELIVER * S)
		if objective == 1 and courier_state == "waiting" and d_courier < 30:
			screens.hint("Space — take the case")
			if act:
				take_case()
		elif objective == 2 and d_deliver < 32:
			screens.hint("Space — hand over the case")
			if act:
				deliver()
		elif d_car < 34:
			screens.hint("Space — get in")
			if act:
				enter_car()
		elif t_draw < flash_until:
			pass
		else:
			screens.hint("Walk to your car — follow the beacon" if objective == 0 else "")
		focus_speed = WALK_SPEED if player.velocity != Vector2.ZERO else 0.0
	else:
		_shunt_traffic(delta)
		if t_draw >= flash_until:
			screens.hint("")
	_update_heat(delta)


func _shunt_traffic(_delta: float) -> void:
	for t in traffic:
		var d: float = car.position.distance_to(t.position)
		if d < 29.0:
			var n: Vector2 = (car.position - t.position) / maxf(d, 0.01)
			var ov := (29.0 - d) / 2.0
			car.position += n * ov
			t.position -= n * ov
			if absf(car.speed) > 55.0 and t.hit_cd <= 0:
				t.hit_cd = 1.5
				t.stun = 1.4
				t.spin = (1.0 if rng.randf() < 0.5 else -1.0) * (2.0 + rng.randf() * 2.0)
				crash_fx(absf(car.speed))
				add_heat(0.45)
				car.speed *= 0.55
			elif t.hit_cd <= 0 and absf(car.speed) > 20.0:
				t.hit_cd = 1.0
				_play_one_shot("thud")
				car.speed *= 0.75


func crash_fx(speed: float) -> void:
	_play_one_shot("crash")
	_shake = minf(0.6, 0.15 + speed * 0.0012)


func enter_car() -> void:
	driving = true
	player.visible = false
	if has_case:
		car.add_child(case_sprite)
		case_sprite.position = Vector2(-3, 0)
		case_sprite.rotation = 0
	_play_one_shot("door")
	if objective == 0:
		set_objective(1)


func exit_car() -> void:
	driving = false
	player.visible = true
	var side := Vector2(0, 1).rotated(car.rotation)
	player.position = car.position + side * 22
	player.rotation = car.rotation
	if has_case:
		player.add_child(case_sprite)
		case_sprite.position = Vector2(2, 6)
		case_sprite.rotation = 0.2
	focus_vel = Vector2.ZERO


func take_case() -> void:
	has_case = true
	courier_state = "leaving"
	player.add_child(case_sprite)
	case_sprite.position = Vector2(2, 6)
	case_sprite.rotation = 0.2
	add_heat(0.9)
	set_objective(2)
	_play_one_shot("pickup")
	flash_until = t_draw + 2.6
	screens.hint("The buyer's men tipped the harbor police — drive clean")
	_play_dispatch("heat1")


func deliver() -> void:
	end_round(true, "DELIVERED", "Case home in %s. Odessa wires $2,500 — and an address." % _fmt_time(score))


func _fmt_time(v: float) -> String:
	return "%d:%02d.%d" % [int(v / 60.0), int(v) % 60, int(v * 10) % 10]


# ---------------------------------------------------------------------------
# Heat and the harbor police
# ---------------------------------------------------------------------------

func stars_for(h: float) -> int:
	if h >= 2.7:
		return 3
	if h >= 1.7:
		return 2
	if h >= 0.75:
		return 1
	return 0


func add_heat(v: float) -> void:
	var before := stars_for(heat)
	heat = minf(3.0, heat + v)
	var now := stars_for(heat)
	shown_stars = now
	if now > before:
		_play_one_shot("alert")
		_play_dispatch("heat%d" % now)


func _update_heat(delta: float) -> void:
	var stars := stars_for(heat)
	var active := 0
	for p in patrols:
		if p.active and not p.leaving:
			active += 1
	if stars > active:
		for p in patrols:
			if not p.active:
				p.activate(self)
				break
	elif stars < active:
		for p in patrols:
			if p.active and not p.leaving:
				p.leaving = true
	var nearest := 1e9
	for p in patrols:
		if p.active and not p.leaving:
			nearest = minf(nearest, p.position.distance_to(focus_pos()))
	heat = maxf(0.0, heat - delta * (0.012 if nearest < 300 else 0.08))
	if nearest < 43 and focus_speed < 26:
		bust_t += delta * (1.0 if driving else 1.7)
		if bust_t >= 1.15:
			end_round(false, "BUSTED", "The harbor police took the case at the quay. Odessa made one call — you walked. Barely.")
			return
	else:
		bust_t = maxf(0.0, bust_t - delta * 2.5)
	shown_stars = stars


func focus_pos() -> Vector2:
	return car.position if driving else player.position


# ---------------------------------------------------------------------------
# Per-frame looks: camera, beacon, arrow, HUD, engine and siren
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	t_draw += delta
	if state == "title":
		var a := t_draw * 0.045
		cam.position = cam.position.lerp(Vector2(sin(a) * 580, cos(a) * 580), 1.0 - exp(-2.0 * delta))
	else:
		var target := focus_pos() + focus_vel.limit_length(100.0) * 0.45
		cam.position = cam.position.lerp(target, 1.0 - exp(-7.0 * delta))
	_shake = maxf(0.0, _shake - delta)
	cam.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake * 6.0 if _shake > 0 else Vector2.ZERO
	var obj_at: Vector2 = OBJECTIVES[objective]["at"] * S
	beacon.position = obj_at
	beacon.queue_redraw()
	var obj_dist: float = focus_pos().distance_to(obj_at) / S
	arrow.visible = state == "playing" and obj_dist > 9
	if arrow.visible:
		arrow.position = focus_pos() + Vector2(0, -44)
		arrow.rotation = (obj_at - focus_pos()).angle() + PI / 2
	boat.position.y = -250 + sin(t_draw * 1.2) * 0.7
	if engine_player:
		if driving and state == "playing":
			if not engine_player.playing:
				engine_player.play()
			engine_player.volume_db = -14.0
		else:
			engine_player.stop()
		engine_player.pitch_scale = 0.55 + absf(car.speed) / 270.0 * 0.9
	if siren_player:
		var near := 1e9
		for p in patrols:
			if p.active and not p.leaving:
				near = minf(near, p.position.distance_to(focus_pos()))
		if near < 900 and state == "playing":
			siren_player.volume_db = linear_to_db(clampf(0.6 * (1.0 - near / 900.0), 0.001, 1.0)) - 10.0
			if not siren_player.playing:
				siren_player.play()
		else:
			siren_player.stop()
	hud.update(self)


# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------

func _setup_audio() -> void:
	AudioServer.add_bus()
	var bi := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bi, "Radio")
	AudioServer.set_bus_send(bi, "Master")
	var hp := AudioEffectHighPassFilter.new()
	hp.cutoff_hz = 320.0
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 3200.0
	var dist := AudioEffectDistortion.new()
	dist.drive = 0.2
	AudioServer.add_bus_effect(bi, hp)
	AudioServer.add_bus_effect(bi, lp)
	AudioServer.add_bus_effect(bi, dist)

	for name in ["engine_loop", "siren_loop", "crash", "thud", "honk", "blip", "pickup", "win", "alert", "door"]:
		var path := "res://assets/audio/%s.wav" % name
		if ResourceLoader.exists(path):
			snd[name] = load(path)
	for name in snd:
		if name.ends_with("_loop") and snd[name] is AudioStreamWAV:
			snd[name].loop_mode = AudioStreamWAV.LOOP_FORWARD
			snd[name].loop_begin = 0
			snd[name].loop_end = int(float(snd[name].data.size()) / 2.0)
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = snd.get("engine_loop")
	add_child(engine_player)
	siren_player = AudioStreamPlayer.new()
	siren_player.stream = snd.get("siren_loop")
	siren_player.bus = "Radio"
	siren_player.volume_db = -40.0
	add_child(siren_player)


func _play_one_shot(name: String) -> void:
	if muted or not snd.has(name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = snd[name]
	p.volume_db = -10.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _play_dispatch(name: String) -> void:
	var path := "res://assets/voice/%s.wav" % name
	if muted or not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = "Radio"
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
