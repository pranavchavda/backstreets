extends Node2D
## Floating arrow above the focus, pointing at the current objective. Drawn pointing up (-y).


func _ready() -> void:
	z_index = 6


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(7, 2), Vector2(-7, 2)]), Pal.ACCENT)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -3), Vector2(5, 7), Vector2(-5, 7)]), Pal.ACCENT.darkened(0.35))
