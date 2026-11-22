class_name Pal
## Fixed noir palette for the standalone build (the Game Vibes version themed
## from the desktop; this one owns its look).

const BG := Color("1a1b26")
const FG := Color("a9b1d6")
const ACCENT := Color("7aa2f7")
const MUTED := Color("414868")
const RED := Color("f7768e")
const GREEN := Color("9ece6a")
const YELLOW := Color("e0af68")
const MAGENTA := Color("ad8ee6")
const CYAN := Color("449dab")
const ORANGE := Color("eb927b")


static func mix(a: Color, t: float, toward: Color = BG) -> Color:
	return a.lerp(toward, t)


static func road() -> Color:
	return mix(BG, 0.55, Color.BLACK)


static func walkc() -> Color:
	return mix(FG, 0.72)


static func quay() -> Color:
	return mix(FG, 0.62)

static func tints() -> Array[Color]:
	return [mix(MUTED, 0.15), mix(ACCENT, 0.45), mix(MAGENTA, 0.5), mix(ORANGE, 0.55), mix(FG, 0.3)]
static func grass() -> Color:
	return mix(GREEN, 0.45)


static func water() -> Color:
	return mix(CYAN, 0.55)


static func rail() -> Color:
	return mix(FG, 0.35)


static func edge() -> Color:
	return mix(BG, 0.35, Color.BLACK)

