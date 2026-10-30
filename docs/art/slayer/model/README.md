# Slayer continuous character model

The current renderer uses a native-detail texture atlas and continuous motion
curves. The previous frame-switched rig and its `*-fixed-model.gif` captures are
rejected historical artifacts; their tests did not establish acceptable motion.

[Full combo](../model-review/actions/combo-right.gif) ·
[Running thrust](../model-review/actions/run-thrust-right.gif) ·
[Quarter-speed combo](../model-review/actions/combo-right-slow.gif)

## Current implementation

- `assets/characters/slayer/model/model.json` records fixed anatomy and texture
  joint anchors. The head stays 32 × 30 logical units; the torso stays 22 units;
  thighs are 16 units and shins 6. No pose independently resizes a body part.
- `motion.json` authors the three attacks and running thrust in seconds. Monotone
  cubic curves connect the grip, sword angle, pelvis, lean and support-arm poses.
  Adjacent combo stages share their entire boundary pose. The finisher and thrust
  have authored recovery to guard. Strike times remain 150/100/100/180 ms.
- Shoulder identity and the three-quarter torso stay consistent throughout the
  action. The old instantaneous front/back texture switches are removed.
- State changes blend pose parameters over 100 ms before solving fixed-length
  joints. Continuous playback no longer holds a discrete pose until the next ANI
  record. Source records are retained for timing/debugging.
- Locomotion has a linear support-foot path, a lifted return path and a gait clock
  that follows actual travel. At runtime the model has one uniform 1.5 scale.
- Native texture pixels are retained in the 2560 × 2560 atlas. The approved model's
  arm pixels are extracted and registered to their real joint anchors. New baggy
  trouser/boot assets avoid the previous long thin calves and duplicated cuffs.

Full-resolution proofs render this same code onto a **1236 × 1273** canvas, with
one fixed scale and floor anchor throughout each sequence. They are not enlarged
80px gameplay captures. Both facings and quarter-speed right-facing proofs are in
`../model-review/actions/`. The proofs hold world translation fixed for anatomy
review; browser input tests exercise actual moving gameplay separately.

## Rebuild and test

```sh
python3 tools/build-slayer-model.py
```

The authoring tool requires Pillow; game startup needs no authoring dependencies.
`source/parts.png`, `proportions.json` and `proportion-guide.png` describe the
rejected version and remain historical. Current anatomy is in runtime `model.json`.

Use **Start → Slayer → Training**, hold **X** for the combo, then double-tap a
direction and press **X** while running. Test both directions; **V** swaps swords,
**Z** uses the skill, **C** jumps and **Esc** pauses.

Geometry/continuity checks supplement rendered review. They do not establish
user acceptance or exact original-client motion fidelity. Gunner remains in scope;
Fighter, Mage and Priest work stays deferred.
