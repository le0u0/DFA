# Slayer run and basic combo redraw

Start now selects a separate eight-frame run and three different basic attack
stages for Slayer, in both independently generated facing directions. These add
58 body poses while keeping swords separate. The source-guided redraw adapts the
approved [chibi v6 design](../chibi-pixel-reference-v6.png); it is an approximation
of the recovered choreography, not a claim of exact pose or pixel fidelity.

The authored atlas retains the original source records: run has eight records;
attacks have 10, 11 and 9 records, respectively, each mapping to seven drawn poses.
Repeated source indices remain repeated, and original raw delays are preserved
in `animations.json`. References are in [the decoded action data](../../roster/dfo-actions/slayer.json).

Basic attacks map the source anticipation and recovery timing independently around
the actor's existing strike time. The first source attack-box frame starts at that
damage boundary. Attack duration, damage, reach, movement, collisions and the
three-stage gameplay combo remain unchanged. This timing adaptation deliberately
differs from playing raw ANI delays at one unscaled rate; engine speed scaling
and transitions have not been recovered.

Idle, walking, running attacks, aerial attacks and class skills still use the
previous poses. Other four characters still use their prototype strips. Further
pose refinement, consistent head scale, grip/occlusion polish and a complete
source-faithful animation set remain outstanding.

## Test on a Mac

With Docker Desktop running, in the existing `dfo-character-animations` checkout:

```sh
git pull --ff-only && npm start
```

Open http://localhost:8080 and choose **Start → Slayer**. For uninterrupted testing,
select **Training · Immortal goblin** in the dungeon dropdown, then enter.

- Hold a direction to walk. Release and quickly double-tap left or right to run.
  Running should lean forward with a separate stride, rather than speed up walking.
- Release movement, then hold **X** to repeat the three-stage basic combo. Check both
  directions; the final stage rises upward. Attacking while running/aerial still uses
  the earlier fallback poses.
- Press **V** to swap the separate sword, and **Esc** to pause/resume.

## Sources and packaging

`source/` contains the unmodified image-generation outputs used for packaging.
`generation-notes.json` records input references and prompt summaries. The corrected
large attack sheet contributes only rows 0, 1 and 3; mixed-facing uppercuts and
bottom-row figures touching neighboring cells were rejected. Separate left/right
uppercut sheets and the right reverse-cut sheet replace those rejected rows.

Rebuild the atlas with Python/Pillow/numpy/scipy:

```sh
python3 tools/normalize-slayer-source-motions.py
```

This first rebuilds the preserved original proof, then isolates the accepted source
figures by their connected opaque regions, registers them to fixed 128px cells with
one scale per source sheet, and maps source ANI records onto those cells. It does
not flip body sprites. Authored grip estimates snap to nearby visible hand pixels;
`grip-review.png` marks their positions for art review. Neither script is needed for
`npm start`; Docker uses the committed PNG/JSON assets. Regenerating only the older
`normalize-slayer-animation-proof.py` replaces this atlas with the historical proof,
so use the source-motion script for the current gameplay assets.

Validation: native Start/roster/dungeon checks, double-tap run selection, all three
combo stages, source attack-box timing at the existing strike boundary, pause and
weapon swapping; Python checks for retained raw frame records/delays, nonempty
unclipped cells, nontransparent grips and independently drawn facings; Docker Web
export and a Chromium gameplay check in both directions.
