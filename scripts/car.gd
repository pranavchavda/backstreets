extends CharacterBody2D
## The getaway car: arcade top-down handling. Positive speed drives toward +x local.


var speed := 0.0
var _crash_cd := 0.0


func _ready() -> void:
	set_meta("game", get_tree().get_first_node_in_group("game"))


func _physics_process(delta: float) -> void:
	var game = get_meta("game")
	if game.state != "playing" or not game.driving:
		velocity = Vector2.ZERO
		return
	var steer := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if Input.is_action_pressed("move_up"):
		speed += 150.0 * delta
	elif Input.is_action_pressed("move_down"):
		speed -= (300.0 if speed > 5.0 else 90.0) * delta
	else:
		speed -= signf(speed) * minf(absf(speed), 70.0 * delta)
	speed = clampf(speed, -90.0, 270.0)
	rotation += steer * 2.5 * clampf(absf(speed) / 70.0, 0.0, 1.0) * signf(speed if speed != 0 else 1.0) * delta
	velocity = Vector2.from_angle(rotation) * speed
	move_and_slide()
	_crash_cd -= delta
	if get_slide_collision_count() > 0 and _crash_cd <= 0:
		if absf(speed) > 75:
			_crash_cd = 0.4
			game.crash_fx(absf(speed))
			game.add_heat(0.3)
			speed *= 0.35
		else:
			speed *= 0.9
	game.focus_vel = velocity
	game.focus_speed = absf(speed)
	if Input.is_action_just_pressed("action") and absf(speed) < 40:
		game.exit_car()
	if Input.is_action_just_pressed("horn"):
		game._play_one_shot("honk")
	queue_redraw()


func _draw() -> void:
	Art.car(self, Pal.mix(Pal.RED, 0.15, Pal.ORANGE), false, 0)
