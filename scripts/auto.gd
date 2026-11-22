extends Node
## Test harness: drives the game with synthetic input and takes screenshots,
## the Godot equivalent of `omarchy agent look page`.
##
## Usage: godot --path . -- --keys="2:action,4:action" --holds="move_up:5,8" --shots=3,6 --quit=9 --dbg=drive
## Keys tap at the given second; holds press start..end; shots saved to user:// and printed.

var args := {}
var game = null
var t := 0.0
var keys: Array = []
var holds: Array = []
var shots: Array = []
var quit_at := 1e9
var _taps: Array = []
var _log_next := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("keys"):
		for pair in String(args["keys"]).split(","):
			var ts: PackedStringArray = pair.split(":", true, 1)
			if ts.size() == 2:
				keys.append([float(ts[0]), StringName(ts[1])])
	if args.has("holds"):
		for pair in String(args["holds"]).split(";"):
			var ts: PackedStringArray = pair.split(":", true, 1)
			if ts.size() == 2:
				var se: PackedStringArray = ts[1].split(",", true, 1)
				if se.size() == 2:
					holds.append([float(se[0]), float(se[1]), StringName(ts[0]), false])
	if args.has("shots"):
		for s in String(args["shots"]).split(","):
			shots.append(float(s))
	if args.has("quit"):
		quit_at = float(args["quit"])


func _process(delta: float) -> void:
	if game == null:
		game = get_tree().get_first_node_in_group("game")
		if game == null:
			return
		if args.has("dbg"):
			game.apply_debug(String(args["dbg"]))
		if args.has("seed"):
			game.set_seed(int(args["seed"]))
	t += delta
	while keys.size() > 0 and keys[0][0] <= t:
		var action: StringName = keys.pop_front()[1]
		Input.action_press(action)
		_taps.append([t + 0.18, action])
	while _taps.size() > 0 and _taps[0][0] <= t:
		Input.action_release(_taps.pop_front()[1])
	for h in holds:
		if t >= h[0] and t < h[1] and not h[3]:
			Input.action_press(h[2])
			h[3] = true
		elif t >= h[1] and h[3]:
			Input.action_release(h[2])
			h[3] = false
	while shots.size() > 0 and shots[0] <= t:
		_shot(int(round(shots.pop_front() * 10)))
	if t >= _log_next:
		_log_next = t + 1.0
		if game != null:
			print("STAT t=%.1f state=%s pos=(%.0f,%.0f) driving=%s speed=%.0f obj=%d heat=%.2f bust=%.2f stars=%d" % [
				game.score, game.state, game.focus_pos().x, game.focus_pos().y,
				game.driving, game.car.speed if "speed" in game.car else -1.0,
				game.objective, game.heat, game.bust_t, game.stars_for(game.heat)])
	if t >= quit_at:
		print("AUTO-DONE")
		get_tree().quit()


func _shot(n: int) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	var path := "user://shot_%02d.png" % n
	img.save_png(path)
	print("SHOT ", ProjectSettings.globalize_path(path))
