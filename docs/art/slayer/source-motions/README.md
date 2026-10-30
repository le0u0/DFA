# Slayer run, basic combo and running thrust

Start now selects a separate eight-frame run and three different basic attack
stages for Slayer, in both independently generated facing directions. These add
72 body cells while keeping swords separate. The source-guided redraw adapts the
approved [chibi v6 design](../chibi-pixel-reference-v6.png); it is an approximation
of the recovered choreography, not a claim of exact pose or pixel fidelity.

The authored atlas retains the original source records: run has eight records;
attacks have 10, 11 and 9 records, respectively, each mapping to seven drawn poses.
Repeated source indices remain repeated, and original raw delays are preserved
in `animations.json`. References are in [the decoded action data](../../roster/dfo-actions/slayer.json).

The [animated review and corrections](../motion-review/README.md) supersede the
initial timing/pose assessment. Slayer now uses the raw source basic durations of
600/650/550ms and first attack-box times of 150/100/100ms, rather than compressing
all stages into 280ms. Running plus X selects its own ten-record, 630ms thrust with
a 180ms strike. This changes the prototype attack cadence; it does not recover the
original engine's speed scaling or cancellation rules.

The first and reverse slash sheets have been redrawn against equipped source poses.
Attack feet registration and guard/thrust blade occlusion were also corrected.
Aerial attacks, class skills, idle and walking retain earlier art. The other active
character is Gunner; Fighter/Mage/Priest development is deferred. Further pose,
grip/occlusion and transition refinement remain outstanding.

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
  directions; the final stage rises upward. Press X while running to test the separate forward thrust; aerial attacks still
  use the earlier fallback poses.
- Press **V** to swap the separate sword, and **Esc** to pause/resume.

## Sources and packaging

`source/` contains the unmodified image-generation outputs used for packaging.
`generation-notes.json` records input references and prompt summaries. The corrected
large attack sheet contributes only rows 0, 1 and 3; mixed-facing uppercuts and
bottom-row figures touching neighboring cells were rejected. Separate left/right uppercut sheets replaced those rejected rows. The equipped-reference
review then superseded both first/reverse-slash sheets with `slash-reviewed.png` and
`reverse-reviewed.png`, and added `dashattack.png`. See the review for rejected final
recovery cells and held follow-through substitutions.

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
