extends Node2D
## A parked car: just the vector art, plus a static body added by game.gd.


func _ready() -> void:
	z_index = 1
	queue_redraw()


func _draw() -> void:
	Art.car(self, get_meta("color", Pal.mix(Pal.MUTED, 0.1)), false, 0)
