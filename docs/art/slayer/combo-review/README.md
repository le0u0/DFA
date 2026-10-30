# Continuous Slayer combo and character proportions

This review records **held X through the entire three-stage combo**, and separately
**idle → double-tap run → running thrust → idle**. It supersedes review of the three
slash strips in isolation.

| Sequence | Before | Updated |
| --- | --- | --- |
| Full combo, right | [GIF](combo-right-before.gif) | [GIF](combo-right-after.gif) |
| Full combo, left | [GIF](combo-left-before.gif) | [GIF](combo-left-after.gif) |
| Run/thrust/idle, right | [GIF](run-thrust-right-before.gif) | [GIF](run-thrust-right-after.gif) |
| Run/thrust/idle, left | [GIF](run-thrust-left-before.gif) | [GIF](run-thrust-left-after.gif) |

The DFA panel uses real input through Start and the normal player state machine.
World translation alone is fixed to compare poses at the same origin. The original
panel replays the decoded equipped sprites and concatenated raw ANI sequences; it
is not a recording of the original client. Its transition/cancellation rules are
not established by this replay. Both panels use the same elapsed-time clock and
50ms samples; the source remains right-facing, as labeled.

## Combo continuity

Two problems caused the apparent hand swap. A queued basic attack briefly displayed
idle at the end of each stage, and the third slash began from a separate pose with
its working hand down by the opposite knee. The second slash ended with that hand
extended across the chest.

- Slayer now chains a held/buffered basic attack directly at recovery end, without
  the idle flash. Other characters retain their previous input behavior.
- Each next stage starts with the preceding stage's exact body pose, grip and sword
  angle. The third slash then crouches with the hand extended, sweeps low, and turns
  away into the rising cut. The same anatomical right hand remains the working hand
  through that torso turn.
- Raw frame records and durations remain unchanged. Reusing the entry pose is a
  deliberate redraw adaptation; the artwork is not a pixel-exact source recreation.

Measured at the actual captured stage boundaries:

| Facing / boundary | Previous grip jump | Updated grip jump | Updated idle gap |
| --- | ---: | ---: | ---: |
| Right, 1 → 2 | 24.5px | 0px | none |
| Right, 2 → 3 | 61.5px | 0px | none |
| Left, 1 → 2 | 25.1px | 0px | none |
| Left, 2 → 3 | 55.3px | 0px | none |

See `before-transitions.json` and `after-transitions.json`. Zero boundary movement
means continuity at the joins; the hand still moves during the intentional swings.

## Fixed character model

The thrust sheet was redrawn against `source/neutral-model.png`, rather than trying
to fix its anatomy by fitting each pose to a rectangle. It now has the neutral
character's larger head and compact torso/legs. One uniform scale is used for all
fourteen thrust poses, with no separate width/height stretching.

The neutral runtime pose has a 30px blond-hair width and a 75px visible standing
height. The previous thrust's hair width was 23–26px. The updated poses measure
28–31px; its standing guard poses are 71–73px tall. The lunge silhouette becomes
shorter as the knees bend while the head stays the same size. These landmark checks
catch gross resizing; they do not substitute for visual review of every limb.

[Fixed-scale pose board](model-scale-review.png) compares idle, walking, running and
thrust guards. `model-measurements.json` contains the before/after measurements.
Future actions must use the same character model and be reviewed across transitions,
as recorded in the development notes. The third-slash back views have also been
redrawn from that model; source-guided artwork remains approximate.

## Test and reproduce

With Docker Desktop running in the current branch:

```sh
git pull --ff-only && npm start
```

Open http://localhost:8080 → **Start → Slayer → Training · Immortal goblin**. Hold
**X** for the complete combo; check both directions. Then double-tap and hold a
direction, press **X**, and release movement to inspect run/thrust/idle transitions.
**V** swaps swords; **Esc** pauses.

The captures require a desktop/OpenGL renderer:

```sh
godot --path . --windowed --resolution 1280x720 --audio-driver Dummy \
  --script tools/capture-slayer-transitions.gd -- --output=res://build/slayer-transitions-after
python3 tools/compare-slayer-transitions.py \
  --captures build/slayer-transitions-after \
  --original /path/to/decoded/slayer/composed \
  --output docs/art/slayer/combo-review --version after
```

The before capture used parent commit `9d88988`. The corrected sources are preserved
in `source/`; the original source index/timing data remains in the earlier motion
review. The left third-slash's clipped final generated cell is rejected and holds
its preceding recovery pose, as do the earlier right first-slash and left
reverse-slash final cells. The corrected thrust now uses all seven complete poses.
