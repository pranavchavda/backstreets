extends CanvasLayer
## Screens: title, pause, game over — plus the bottom hint line.


var title_panel: Control
var pause_panel: Control
var over_panel: Control
var over_title: Label
var over_detail: Label
var over_best: Label
var over_next: Label
var hint_lbl: Label


func _panel() -> Control:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	p.set_meta("v", v)
	return p


func _label(v: Node, text: String, size: int, color: Color = Pal.FG) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	return l


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	title_panel = _panel()
	var tv: Node = title_panel.get_meta("v")
	_label(tv, "BACKSTREETS", 58, Pal.ACCENT)
	_label(tv, "A top-down city getaway. Chapter 1: The Handoff.", 17)
	_label(tv, "WASD / arrows to move · Space for the chapter intro", 17, Pal.ACCENT)
	_label(tv, "Esc quits · M mutes", 14, Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.55))
	root.add_child(title_panel)

	pause_panel = _panel()
	var pv: Node = pause_panel.get_meta("v")
	_label(pv, "PAUSED", 44, Pal.ACCENT)
	_label(pv, "Esc — resume · Q — quit", 17)
	root.add_child(pause_panel)

	over_panel = _panel()
	var ov: Node = over_panel.get_meta("v")
	over_title = _label(ov, "GAME OVER", 44, Pal.ACCENT)
	over_detail = _label(ov, "", 17)
	over_best = _label(ov, "", 17, Pal.ACCENT)
	over_next = _label(ov, "", 14, Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.55))
	_label(ov, "Space — play again", 17)
	root.add_child(over_panel)

	hint_lbl = Label.new()
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_lbl.position = Vector2(640, 676)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 17)
	root.add_child(hint_lbl)

	title_panel.visible = false
	pause_panel.visible = false
	over_panel.visible = false
	hint_lbl.visible = false


func show_title() -> void:
	title_panel.visible = true
	pause_panel.visible = false
	over_panel.visible = false


func show_pause() -> void:
	pause_panel.visible = true
	over_panel.visible = false


func hide_pause() -> void:
	pause_panel.visible = false


func show_over(won: bool, title: String, detail: String, best: float) -> void:
	over_title.text = title
	over_detail.text = detail
	over_next.text = "On the ferry manifest: a name you had not seen in two years. Sable is in town.\nChapter 2 — The Ferry Manifest." if won else ""
	over_panel.visible = true
	title_panel.visible = false
	pause_panel.visible = false


func hint(text: String) -> void:
	hint_lbl.text = text
	hint_lbl.visible = text != ""


func hide_all() -> void:
	title_panel.visible = false
	pause_panel.visible = false
	over_panel.visible = false
