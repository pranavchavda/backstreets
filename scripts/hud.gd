extends CanvasLayer
## HUD: objective line, mission clock, wanted stars, bust bar, best time.


var objective_lbl: Label
var clock_lbl: Label
var best_lbl: Label
var stars: Control
var bust_bg: ColorRect
var bust_fill: ColorRect


class StarsControl extends Control:
	var count := 0
	var flashing := false
	var t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(110, 24)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		for i in range(3):
			var on := i < count
			var c := Pal.mix(Pal.FG, 0.55) if on else Pal.mix(Pal.FG, 0.55, Pal.BG).darkened(0.0)
			if not on:
				c = Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.18)
			if on and flashing:
				c.a = 0.55 + 0.45 * absf(sin(t * 10.0))
			draw_colored_polygon(Art.star_points(Vector2(12 + i * 28, 12), 10.0), c)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left := VBoxContainer.new()
	left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left.offset_left = 18
	left.offset_top = 14
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)
	objective_lbl = Label.new()
	objective_lbl.add_theme_font_size_override("font_size", 15)
	objective_lbl.modulate = Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.85)
	left.add_child(objective_lbl)
	clock_lbl = Label.new()
	clock_lbl.add_theme_font_size_override("font_size", 24)
	left.add_child(clock_lbl)

	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.offset_right = -18
	right.offset_top = 14
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right)
	stars = StarsControl.new()
	right.add_child(stars)
	bust_bg = ColorRect.new()
	bust_bg.custom_minimum_size = Vector2(110, 7)
	bust_bg.visible = false
	right.add_child(bust_bg)
	bust_fill = ColorRect.new()
	bust_fill.color = Pal.RED
	bust_fill.position = Vector2.ZERO
	bust_fill.size = Vector2(0, 7)
	bust_bg.add_child(bust_fill)
	best_lbl = Label.new()
	best_lbl.add_theme_font_size_override("font_size", 14)
	best_lbl.modulate = Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.6)
	right.add_child(best_lbl)


func update(g) -> void:
	visible = g.state in ["playing", "paused", "over"]
	var obj_at: Vector2 = g.OBJECTIVES[g.objective]["at"] * g.S
	var dist := int(round(g.focus_pos().distance_to(obj_at) / g.S))
	objective_lbl.text = "%s  ·  %d m" % [String(g.OBJECTIVES[g.objective]["text"]).to_upper(), dist]
	clock_lbl.text = g._fmt_time(g.score)
	best_lbl.text = "BEST  %s" % ("—" if g.best < 0 else g._fmt_time(g.best))
	stars.count = g.shown_stars
	stars.flashing = g.bust_t > 0.03
	bust_bg.visible = g.bust_t > 0.03
	if bust_bg.visible:
		bust_fill.size.x = bust_bg.size.x * clampf(g.bust_t / 1.15, 0.0, 1.0)
