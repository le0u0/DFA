# Slayer motion comparison and running attack

The first runtime redraw was not validated adequately in motion. The comparisons
below capture the **actual Start renderer** before and after this correction, beside
an original **ANI replay from the supplied files**. The original client was not run.
The source panel uses its decoded equipped compositions, raw delays and a fixed 0.7
scale; its final pose is held after ANI end. Source layering remains a review
composition. World translation is fixed in the DFA capture so that poses can be
compared at the same origin. This is not a recording of original-client gameplay.

## Animated comparisons

Each GIF uses a shared elapsed-time clock, 50ms samples, and labels for the active
runtime record and source image. The source stays in the supplied right-facing view,
including in left-facing comparisons; it is never silently mirrored.

| Motion | Before | Corrected |
| --- | --- | --- |
| Run | [GIF](run-right-before.gif) | [GIF](run-right-after.gif) |
| First slash | [GIF](attack1-right-before.gif) | [GIF](attack1-right-after.gif) |
| Reverse slash | [GIF](attack2-right-before.gif) | [GIF](attack2-right-after.gif) |
| Rising slash | [GIF](attack3-right-before.gif) | [GIF](attack3-right-after.gif) |
| Running thrust | [Generic fallback GIF](dashattack-right-before.gif) | [Separate thrust GIF](dashattack-right-after.gif) |

Matching `*-left-*.gif` files cover the other runtime facing.

## Findings and corrections

- All basic stages previously finished in **280ms**, compared with the raw source
  sequences of **600, 650 and 550ms**. This skipped through the visible windup and
  returned to idle while the original sequence was still recovering. Slayer now
  uses those raw durations, with first attack-box times of **150, 100 and 100ms**.
  This intentionally slows the prototype attack cadence; damage and reach values
  are unchanged. Raw ANI timing is not proof of original engine attack-speed scaling.
- The first slash incorrectly kept punching forward. Its redraw now follows through
  low behind the torso. The reverse slash now rotates toward the viewer and finishes
  with the working arm behind the actor, matching the equipped source mechanics more
  closely. These remain chibi approximations, not exact copies.
- Attack registration uses the feet rather than the entire silhouette width. An
  extended arm no longer pushes the whole body backward merely by widening its bounds.
- A blade drawn entirely behind the body disappeared during windup. The blade now
  draws in front for guard/thrust windups while the hilt stays under the fingers.
- Running plus X previously selected the historical generic attack sheet. It now
  selects a separate **running thrust**, preserving ten source records, seven image
  references and **630ms** total duration; its first attack box starts at **180ms**.
  The previous lunge movement window stays short so the longer recovery does not
  increase travel distance. The combo timeout accounts for the longer basic stages.

One generated final recovery cell in each of the right thrust, right first slash,
and left reverse slash touched the image edge. Those clipped cells are rejected;
the preceding follow-through is held instead. That is a documented redraw deviation,
not a newly recovered source pose. The third basic slash still uses the previous
source-guided redraw, and idle/walk, aerial and skill art remain unfinished. Gunner
remains the other active character; Fighter/Mage/Priest work stays deferred.

## Test

With Docker Desktop running in the `dfo-character-animations` checkout:

```sh
git pull --ff-only && npm start
```

Open http://localhost:8080 → **Start → Slayer**, choose **Training · Immortal goblin**,
and enter. Release movement and hold **X** for the three-stage chain. Then double-tap
and hold left/right and press **X while still running** for the thrust. **V** swaps
the separate sword; **Esc** pauses. Check both facings.

## Reproduce the capture

A desktop display/OpenGL renderer is needed; headless tests alone cannot validate
how the animation looks. The capture tool enters through Start and drives the same
actor/visual state at deterministic times, with translation fixed for comparison:

```sh
godot --path . --windowed --resolution 1280x720 --audio-driver Dummy \
  --script tools/capture-slayer-motions.gd -- --output=res://build/slayer-review-after
python3 tools/compare-slayer-motions.py \
  --captures build/slayer-review-after \
  --original /path/to/decoded/slayer/composed \
  --output docs/art/slayer/motion-review --version after
```

The before GIFs were captured from parent commit `b41ef8e`. The comparison JSON files
record timing and source names. `dashattack-source.json` comes from
`character/swordman/animation/dashattack.ani` in the verified uploaded reference ZIP.
