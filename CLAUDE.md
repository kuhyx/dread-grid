# CLAUDE.md — dread-grid

Godot 4.7.2 / GDScript. Five horror concepts x three perspectives = 15 small
games in one project. Remote: `github.com/kuhyx/dread-grid` (public,
experiment). `README.md` has the commands; `DOCS-design.md` has the agreed
per-concept rules and done thresholds. This file is the code map and the
rules that are not obvious from the code.

## Rules

- **Every GDScript warning is an error** (`project.godot [debug]`), including
  `inferred_declaration`, `return_value_discarded` and the `unsafe_*` family:
  no `:=`, every `var`/`const`/`for` iterator is typed, every non-void return
  is used or bound (`var _ok: bool = arr.append(x)` for Packed arrays), and a
  Variant (Dictionary/Array element) is bound to a typed local before being
  passed as an argument. `scripts/lint.sh` fails otherwise.
- No `# gdlint:ignore` / warning-ignore annotations without asking first.
- 250 lines per file, code and prose (shared gate). Split, do not squeeze.
- No binaries in git. GUT (`addons/gut/`) and `assets` (symlink into
  `../dread-grid_binaries/`) are gitignored and made by `install.sh`.
- After adding a `class_name` script run `godot --headless --path . --import`
  or every user of it fails with "Could not find type".
- Never open a window on the live display: screenshots go through
  `scripts/screenshot.sh` (Xvfb). Heavy runs go through `~/.claude/scripts/capped.sh`.

## Architecture: rules once, three views

- `src/core/concept.gd` — base of every concept. Pure RefCounted rules: state,
  `perform(action: StringName) -> bool`, `advance(delta)`, `hud_line()`,
  `bot_action()`, signals `message(text)` and `finished(won)`. No nodes.
- `src/logic/<concept>/` — one concept's rules + data + its bot. The bot may
  read hidden state (it is a test driver, not an AI opponent).
- `src/view/<concept>/<concept>_{fps,topdown,text}.gd` — thin views, each
  `extends FpsView | TopdownView | TextView` (`src/view/common/`). They
  build nodes from concept state, map keys to actions (`extra_keys()`),
  and animate in `on_acted()`/`refresh()`. No rules in views.
- Autodrive feeds `concept.bot_action()` through the view's own `act()`,
  so `scripts/autodrive_all.sh` exercises the real view code path.
- `BotRunner.play(concept)` plays a concept with no view; tests use it to
  prove every concept is winnable on many seeds.

Shared vocabulary: `forward`, `back`, `turn_left`, `turn_right` (WASD /
arrows, via `GameView.MOVE_KEYS`) plus concept actions (`turn_back`, `hide`,
`flag`, `record`, `ping`, `photo`, `look`, `wait`).

## Code map

- `src/main.gd` — launcher or `--game=`; screenshot, timeout, exit codes
  (0 won, 1 lost, 2 timeout, 3 bad game id, 4 screenshot failed).
- `src/core/` — `launch_options`, `registry` (the 5x3 table), `concept`,
  `cell_grid` (walls, BFS, line of sight), `grid_walker` (cell + facing),
  `maze_gen`, `prop` (data-row objects), `hud`, `sfx` (procedural tones,
  CC0 samples, music beds), `bot_runner`, `game_view`, `launcher`.
- `src/view/common/` — `fps_view` (quarter-res SubViewport + `psx.gdshader`
  vertex snapping + fog; grid-step camera; `build_grid`, `add_box`,
  `add_figure`, `add_label`, `add_light` into `target`), `topdown_view` (fog
  of war, `draw_overlay`), `text_view` (log + prompt, `words()`,
  turn-based `tick_seconds()`).
- `content/music_beds.json` + `tools/render_music.sh` — procedural beds
  (`~/src/utils/music_theory`, pinned tag). `assets.lock.json` +
  `tools/fetch_assets.sh` — CC0 samples, sha256-pinned; credits in
  `DOCS-credits.md`.
