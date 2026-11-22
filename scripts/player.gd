extends CharacterBody2D
## Rue on foot: eight-way walking, faces the direction of travel.


func _ready() -> void:
	var game = get_tree().get_first_node_in_group("game")
	set_meta("game", game)


func _physics_process(delta: float) -> void:
	var game = get_meta("game")
	if game.state != "playing" or game.driving:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * game.WALK_SPEED
	if dir != Vector2.ZERO:
		rotation = lerp_angle(rotation, dir.angle(), 1.0 - exp(-14.0 * delta))
	move_and_slide()
	game.focus_vel = velocity
	queue_redraw()


func _draw() -> void:
	Art.ped(self, Pal.ACCENT, false)
