extends Node2D
## The buyer's boat, bobbing by Pier 7.


func _ready() -> void:
	z_index = 0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-65, -22, 130, 44), Pal.mix(Pal.FG, 0.5, Color.BLACK))
	draw_rect(Rect2(10, -17, 44, 34), Pal.mix(Pal.MUTED, 0.2))
	draw_circle(Vector2(-70, 0), 3.0, Pal.ACCENT)
