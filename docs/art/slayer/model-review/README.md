# Slayer model and action review

The rejected frame-switched rig has been replaced with native-detail parts and
continuous, seconds-based motion. The full combo, running thrust and recoveries
are implemented in the game renderer. Review the actual moving artwork below.

## Current action proofs — 1236 × 1273

| Action | Right | Left | Quarter speed |
| --- | --- | --- | --- |
| Complete three-hit combo | [GIF](actions/combo-right.gif) | [GIF](actions/combo-left.gif) | [GIF](actions/combo-right-slow.gif) |
| Idle/run/thrust/recovery | [GIF](actions/run-thrust-right.gif) | [GIF](actions/run-thrust-left.gif) | [GIF](actions/run-thrust-right-slow.gif) |

Every proof uses the same body dimensions and one fixed scale/floor anchor.
Textures are rendered from the detailed atlas, rather than magnifying low-resolution
screenshots. Canvas dimensions match the approved appearance reference. Space is
reserved for the complete weapon arc; individual poses are never fitted to bounds.
Capture metadata is in [proof.json](actions/proof.json).

The source attack durations and strike events are preserved. The custom poses use
a consistent three-quarter view, connected shoulders, weight shifts and a forward
thrust with recovery. Walk/run foot support follows travel; action changes blend
parameters before IK, retaining limb lengths. See [implementation](../model/README.md).

## Appearance reference and rejected motion

- [Approved appearance reference](../chibi-pixel-reference-v6.png)
- [Weapon-free model reference, 1236 × 1273](model-candidate-1236x1273.png)
- [Rejected combo frames](rejected-combo-frames.png)
- [Rejected run/thrust frames](rejected-run-thrust-frames.png)

The old 620 × 288 GIF used an approximately 80px actor. Its torso switches,
disconnected joints and gait faults are rejected. Those captures remain historical.
The new proofs replace them for current review.

## Smoothness and continuity gate

Review the entire combo and thrust at normal speed, quarter speed and frame by
frame in both directions. Check stable anatomy, continuous shoulder/elbow/wrist
paths, natural knees, foot support, weapon grip and complete recovery. A failed
boundary or distorted frame rejects the sequence. Passing numeric checks does
not substitute for visual judgment or user acceptance.

After rendering, exercise tap/hold/buffered attacks, repeated combos and thrusts,
direction changes, interruption, equipment changes and pause in moving gameplay.
A stationary pose proof alone cannot establish that those transitions work.
