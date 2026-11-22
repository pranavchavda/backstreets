extends Node2D
## The case: Odessa's goods. Reparents between courier, player and car roof.


func _ready() -> void:
	z_index = 5
	queue_redraw()


func _draw() -> void:
	Art.case_art(self)
