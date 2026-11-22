# AGENTS.md — Backstreets Godot port (pick up here)

Project: `~/Work/backstreets/` — a Godot 4.7 (gl_compatibility) port of the
Game Vibes single-file game `~/Games/vibes/backstreets/` (chapter 1 verified
working there, including the D/A steering-mirror fix).

Git: repo initialized, one checkpoint commit (`8b9ad34`).
Rules: no pushes without user approval.

## What works (verified)

- Full lifecycle: title → 5 story panels → round → pause → over → retry; Esc quits.
- Walk/drive, enter/exit car, case pickup, delivery win, heat/stars, patrol chase/ram, bust fail, best-time save (`user://save.cfg`).
- Physics collisions via CharacterBody2D + StaticBody2D; mission/traffic/ped/patrol
  logic is a unit-for-unit port (scale S = 10, speeds ×10).
- 10 numpy WAVs (`tools/make_audio.py`), 4 SVG comic panels, project icon.
- 7 OpenRouter voices (`tools/make_voice.py`, pcm16 path): dispatcher
  heat1/2/3/lost/busted, Odessa (`odessa` on panel 3) + `take`; two 30 s Lyria
  clips (`radio_bed` in car, `title_theme` on title/story/over). Radio bus
  (320 Hz HP + 3.2 kHz LP + distortion) applies to siren + dispatcher lines.
- Auto test harness: autoload `scripts/auto.gd`
  (`--keys=t:action --holds=a:x,y --shots=a,b --quit=t --dbg=drive|bust|win --seed=n`),
  prints `STAT …` lines + `SHOT` PNG paths. `holdD`/`drive`/`bust`/`win` scenarios
  verified by telemetry: W drives up-screen, D steers screen-right, BUSTED fired,
  DELIVERED fired with best time saved.

## How to test

```bash
cd ~/Work/backstreets
godot --headless --path . --import                                   # after adding assets
godot --headless --path . --quit-after 120                          # parse/boot check
godot --headless --path . --check-only --script res://scripts/x.gd  # per-file parse
# windowed run with auto input + screenshots (needs the desktop session):
godot --path . --resolution 1280x720 -- --keys="2:action,..." --holds="move_left:4.5,9.2" --shots=9,12 --quit=15
```

## Open work (in this order)

1. **Screenshots blocked on vision rate limit** (image reads 429'd until
   2026-11-23 05:39 UTC). Shots land in
   `~/.local/share/godot/app_userdata/Backstreets/shot_*.png` — view pending:
   - shot_90/120/135: dbg=drive (walk to car, enter, drive north)
   - story panel + hud + title shots
   Fix whatever they show; iterate with `--dbg=` + auto runs.
   - Known cosmetic suspicion: `bust_fill.size.x` may exceed its container when
     bust decays while visible (review in hud.gd).
2. **Voice wiring is done but unverified audibly** — confirm the dispatch lines,
   Odessa, and music actually trigger (add temporary `print()` in
   `_play_dispatch` if needed) and that Lyria loops end-to-end cleanly.
3. **AI sprite pass (stretch)**: replace vector-drawn sprites with nano-banana
   art. Pipeline: `python ~/.claude/skills/nano-banana/scripts/nano_banana.py
   generate …` (OPENROUTER_API_KEY is set; Gemini-direct key is dead, use `/`
   OpenRouter model IDs; Recraft available for vector-style; multi `-r` for
   character consistency). Top-down N/S/E/W Rue sheet + car sprite + fresher
   comic panels; `magick -fuzz 12% -trim` for spritesheets.
4. **Commit** the voice pass + fixes; push only with user approval.

## Known architecture facts (don't re-derive)

- Y-down 2D: forward = `Vector2.from_angle(rotation)`, rotation 0 faces +x;
  camera at +y-offset looking north => north is screen-up.
- Headless `godot` compiles everything: `check-only` per file, full boot with
  `--quit-after`. Parse error lines in `.gd` are often off — verify with `cat -A`.
- `game.gd` must stay untyped for `player/car/courier` (script vars on native
  nodes); annotate locals that mix Variant ternaries (`var x: float = …`).
- AudioServer effect method is `add_bus_effect` (not `bus_add_effect`).
- OpenRouter speech endpoint allowlist excludes chat-audio models; use the
  `/chat/completions` audio modality (`modalities`, `audio.voice/format`,
  `stream: true`, SSE base64 `delta.audio.data`, `pcm16` for speech).
  Lyria clips come back mp3 — transcode with ffmpeg.
- Synthetic `Input.action_press` in the harness triggers
  `is_action_just_pressed` but NOT `_unhandled_input` events; story/story-advance
  must read state in `_process`. `apply_debug` must run on transitions into
  `playing` (start_round resets it). Story needs a 0.5 s open-cooldown so the
  opening press doesn't eat panel 1.
