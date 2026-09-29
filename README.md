# dread-grid

Five horror concepts, each playable three ways: **15 small games** in one
Godot 4.7 project. An experiment in how much a fear depends on how you see it.

|  | First person | Top-down | Text + audio |
|---|---|---|---|
| **Anomaly Loop** — spot what changed, turn back | ✓ | ✓ | ✓ |
| **Stalker** — 3 keys, one exit, something hunting you | ✓ | ✓ | ✓ |
| **Wrong Place** — flag what is wrong in the house | ✓ | ✓ | ✓ |
| **Found Footage** — record 5 events before the battery dies | ✓ | ✓ | ✓ |
| **Blind Descent** — navigate a trench by sonar and photos | ✓ | ✓ | ✓ |

Each concept's rules are written once (`src/logic/`); each perspective is a
thin view over them (`src/view/`). Rules and done thresholds: `DOCS-design.md`.

## Run

```bash
~/src/dread-grid/install.sh        # Godot, GUT, dev tools, assets, hooks
~/src/dread-grid/run.sh            # the 5x3 launcher
~/src/dread-grid/run.sh --game=stalker/fps --seed=7
```

Keys: WASD / arrows move and turn; each game lists its own extra keys on
screen. R restarts after an ending, Esc goes back. Text games: type `help`.

## Check

```bash
scripts/lint.sh            # gdlint, gdformat, warnings-as-errors parse
scripts/test.sh            # GUT unit tests, incl. every concept winnable on many seeds
scripts/autodrive_all.sh   # all 15 games played to a win by their bots, headless
scripts/screenshot.sh anomaly/fps shot.png   # Xvfb capture, never your display
scripts/check.sh           # all of the above + the shared gates
```

## Assets

Procedural: geometry, the PS1 look (`src/view/common/psx.gdshader`) and the
music beds (`content/music_beds.json`, rendered by `tools/render_music.sh`
with `music_theory` from `kuhyx/utils`). Sampled: CC0 sounds pinned by
sha256 in `assets.lock.json`, credited in `DOCS-credits.md`. Nothing binary
is committed; `install.sh` builds `assets/` in `../dread-grid_binaries/`.
