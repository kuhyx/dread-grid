# Design — the 5 x 3 grid

Agreed with kuhy on 2026-09-29. Every game ships when its autodrive run exits
0 (`scripts/autodrive_all.sh`) and an Xvfb screenshot shows it working.

| Concept | Win | Lose | Text + audio | Top-down |
|---|---|---|---|---|
| Anomaly loop | 8 correct calls in a row, 10 anomalies | wrong call resets the streak | the room described each step; the anomaly is a changed sentence | the corridor from above; the anomaly is a visible change |
| Stalker | 3 keys, then the exit | caught -> restart | commands (listen / hide / move); footsteps louder as it nears | vision cone, fog of war; it patrols and hunts noise |
| Wrong place | flag 6 of 8 wrong things, then reach the end | none; time and false flags are the score | a walk-through in prose; flag odd objects | a house from above; flag odd objects |
| Found footage | record 5 events before the battery (~6 min recording) dies | battery empty, or too few events left | a tape transcript with timecodes; record costs battery | a camcorder view cone; recording drains the battery |
| Blind descent | reach 4 waypoints by coordinates | hull reaches 0 from collisions | coordinates + sonar as text and stereo beeps | a black map; ping / photo reveal patches for 2 s |

Look: procedural low-poly PS1 (vertex snapping, quarter-res, fog) and
procedural music; CC0 samples for footsteps, doors, static and impacts.

## Concept notes

**Anomaly loop** (`src/logic/anomaly/`). An 8-segment corridor. Props and
the ten anomalies are data rows (`AnomalyCatalog`); views render props
generically, so a new anomaly is a row. First loop is always normal; 50 %
anomaly chance after, never the same anomaly twice running.

**Stalker** (`src/logic/stalker/`). 15x15 maze with loops, 3 keys in far
dead ends, exit in the far corner, lockers to hide in. The stalker patrols,
hunts on sight (6 cells, line of sight) or on noise (walking, 3 cells), and
catches on the same or an adjacent cell unless you are hidden and it did not
see you hide. Hunting speed is just under the player's.

**Wrong place** (`src/logic/wrong_place/`). A hand-authored house; ~16
objects, 8 of them wrong per seed from a pool of self-evidently wrong
variants (upside-down painting, red bathwater, chair on the ceiling...).
Flag the object you face. The back door opens at 6 found.

**Found footage** (`src/logic/found_footage/`). A building of rooms, 7
scripted events triggered by proximity, each active a few seconds. An event
is captured if you are recording, facing it, in line of sight. Recording
empties the battery in 6 min (100/360 % per s), idle drains 100/1800 % per s;
lose when empty or when fewer events remain than you still need.

**Blind descent** (`src/logic/blind_nav/`). Iron-Lung-style: a rock-strewn
trench you never see directly. Coordinates, sonar ping (8 directions),
photo (a 5x5 patch ahead). A collision costs 25 hull. 4 waypoints, all
reachable (BFS-checked at generation).
