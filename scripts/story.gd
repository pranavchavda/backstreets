extends CanvasLayer
## The chapter intro: four comic panels over the dimmed city, then a title card.
## Space (or click) advances; Esc goes back to the title screen.


var panels: Array = []
var idx := 0
var game
var _cooldown := 0.0


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG.r, Pal.BG.g, Pal.BG.b, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var captions := [
		"Vesper Harbor let you out of Blackreef at dusk.\nTwo years inside, and the city didn't even look up.",
		"One payphone was ringing before you'd crossed the block.\nOnly one person calls that phone.",
		"ODESSA: \"My courier froze at Pier 7. My buyer sails on the tide.\nBring the case home, Rue, and we'll talk about your cut.\"",
		"Your cut. The one that grew legs while you sat in a cell.\nYou hang up, and start walking.",
	]
	for i in range(4):
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_CENTER)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(640, 356)
		var path := "res://assets/panels/panel%d.svg" % (i + 1)
		if ResourceLoader.exists(path):
			tr.texture = load(path)
		v.add_child(tr)
		var cap := Label.new()
		cap.text = captions[i]
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 18)
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.custom_minimum_size = Vector2(640, 0)
		v.add_child(cap)
		root.add_child(v)
		panels.append(v)

	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	var ch := Label.new()
	ch.text = "CHAPTER ONE"
	ch.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ch.add_theme_font_size_override("font_size", 15)
	ch.modulate = Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.6)
	card.add_child(ch)
	var h := Label.new()
	h.text = "THE HANDOFF"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_size_override("font_size", 54)
	h.add_theme_color_override("font_color", Pal.ACCENT)
	card.add_child(h)
	var body := Label.new()
	body.text = "Meet the courier at Pier 7. Deliver the case to the ferry terminal.\nCollisions bring the harbor police — a clean drive keeps them away."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 17)
	card.add_child(body)
	var keys := Label.new()
	keys.text = "Space to start · Esc to go back"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.add_theme_font_size_override("font_size", 15)
	keys.modulate = Color(Pal.FG.r, Pal.FG.g, Pal.FG.b, 0.55)
	card.add_child(keys)
	root.add_child(card)
	panels.append(card)

	visible = false


func open(g) -> void:
	game = g
	idx = 0
	_cooldown = 0.5
	visible = true
	_show()


func _show() -> void:
	for i in range(panels.size()):
		panels[i].visible = i == idx


func _process(dt: float) -> void:
	if not visible:
		return
	_cooldown = maxf(0.0, _cooldown - dt)
	if _cooldown > 0.0:
		return
	if Input.is_action_just_pressed("action"):
		advance()
	elif Input.is_action_just_pressed("pause"):
		visible = false
		game.state = "title"
		game.screens.show_title()


func advance() -> void:
	if game:
		game._play_one_shot("blip")
	idx += 1
	if idx >= panels.size():
		visible = false
		game.start_round()
		return
	if idx == 2:
		game._play_dispatch("odessa")
	_show()
