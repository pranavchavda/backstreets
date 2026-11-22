extends Node2D
## Objective beacon: pulsing rings at the target.


func _ready() -> void:
	z_index = 6


func _draw() -> void:
	var game = get_tree().get_first_node_in_group("game")
	if game == null:
		return
	var r := 17.0 + sin(game.t_draw * 3.0) * 2.5
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Pal.mix(Pal.GREEN, 0.1, Color.WHITE), 2.5)
	draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 32, Color(Pal.GREEN.r, Pal.GREEN.g, Pal.GREEN.b, 0.5), 1.5)
