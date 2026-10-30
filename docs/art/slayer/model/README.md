# Slayer's fixed character model

The earlier independent whole-body sheets changed anatomy between actions. Hair
width and silhouette height did not detect long thighs, thin calves or a narrow
torso. Those checks were insufficient and the earlier claim of consistent body
proportions was premature.

Slayer now uses **one model made from fixed body parts and fixed-length joints**
for idle, walking, running, all three basic attacks, running thrust, aerial attacks
and skill placeholders. Actions pose that same body. They cannot enlarge the head,
lengthen the legs, or narrow the limbs to fit a sprite cell.

[Proportion guide](proportion-guide.png) · [Recorded dimensions](proportions.json)

[Full combo GIF](combo-right-fixed-model.gif) · [Run/thrust/idle GIF](run-thrust-right-fixed-model.gif)

## Canonical proportions

These are explicit pixel-art authoring targets adapted from the approved
[chibi v6 design](../chibi-pixel-reference-v6.png), rounded for an 80px neutral
standing model. They are not inferred measurements of the discarded animation
sheets. The source of truth shipped by the game is
`assets/characters/slayer/model/model.json`.

| Region | Target | Neutral height share |
| --- | ---: | ---: |
| Crown through chin | 30px high, 32px wide | 37.5% |
| Chin through hips, including neck/pelvis | 22px | 27.5% |
| Hips through soles, including boots | 28px | 35% |

| Structural measurement | Fixed size |
| --- | ---: |
| Shoulder joint span / chest / waist | 24px / 24px / 18px |
| Hip joint span | 16px |
| Thigh length / trouser thickness | 13px / 14px |
| Shin length / thickness | 9px / 11px |
| Boot | 16px wide × 7px high, overlapping the ankle |
| Normal upper arm / forearm | 11px / 9px long; 8px / 7px thick |
| Cursed upper arm / forearm | 12px / 10px long; 10px / 9px thick |

Feathers, baggy clothing and the chain extend outside structural joint widths.
Lunges and crouches reduce projected height by bending joints. They do not change
bone lengths, part sizes or body proportions. Front/back heads share the same
32×30 dimensions; both boot facings and torso views share fixed dimensions too.

## Renderer change

`game/slayer_model.gd` solves two-segment arms and legs with constant lengths. An
unreachable hand/foot target is clamped to the model's reach rather than stretching
a limb. Fixed-width envelopes under the painted parts preserve thick trouser legs
and prevent a narrow texture region from making a limb look thin during rotation.
The head and body parts are never resized per action or frame. Front/back clothing
and independently drawn head facings retain the character design and arm identities.

This replaces the independent whole-body strips in Slayer's renderer. Those PNGs
remain historical pose/timing references; they no longer draw Slayer's anatomy.
Raw ANI record order and timing, separate swords, the connected combo entry poses,
combat values and collision/movement rules are retained. The animation style is now
a posed cutout model rather than a sequence of independently drawn whole bodies.
Pose choreography, painted joint overlap and equipment occlusion remain subject to
art review; fixed anatomy does not establish exact original-game motion fidelity.

## Review and test

Use `npm start`, then **Start → Slayer → Training · Immortal goblin**. Hold X for the
full combo, then double-tap a direction and press X while running. Check both
facings, jumping, skill and V equipment swaps. Esc pauses.

The GIFs in this directory record full held-input sequences through Start. The
original panel is a replay of decoded source ANI files, not original-client footage.
World translation is fixed for pose comparison. The older whole-body version is
preserved as `*-before-model.gif`.

## Rebuild and verify

`source/parts.png` is the unmodified image-generation output created from the
approved character reference as eighteen separate painted parts. The prompt asked
for orthographic head views, wide vest/pelvis, short thick trouser segments, both
boots, and separate normal/cursed arm segments. Parts are calibrated **once** into
this model, not independently at each pose. A chain is drawn separately so it does
not distort the forearm's structural width.

```sh
python3 tools/build-slayer-model.py
```

The authoring tool requires Pillow. Runtime startup needs no authoring dependencies.
Native model checks visit every action/frame and verify actual thigh, shin, upper
arm, forearm and torso lengths, plus whole-pose continuity between combo stages.
They supplement the gameplay tests and rendered sequence review. The source model
is Slayer-specific; Gunner needs its own fixed model, and the other three classes
remain deferred under the development scope.
