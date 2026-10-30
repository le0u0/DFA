# Development notes

## Active scope — 2026-10-30

Focus development on **Slayer and Gunner only until the complete game is playable
from start to finish**. This scope reduction is intended to shorten development time.

- Prioritize Slayer and Gunner art, animations, combat, equipment and testing.
- Continue shared gameplay, dungeon, enemy, progression and runtime work needed for
  the complete playable game.
- Defer new Fighter, Mage and Priest character work until that milestone. Keep their
  existing implementations available; shared compatibility fixes may still apply.

Do not expand the active character scope without a new direction from the user.

## Animation acceptance

Preserve the same character proportions across every action. Use the neutral
character as the fixed model: head size, torso and limb lengths must not change
when switching animations. Crouching changes joint angles, not character scale.
Compare complete held-input combos and idle/run/running-attack/idle transitions,
including stage boundaries, rather than accepting isolated pose strips.

The [earlier 80px rig dimensions](art/slayer/model/README.md) and its
`model.json` describe a rejected runtime prototype, not accepted character
proportions. Use the approved high-resolution appearance as the authoring reference
and follow the model-first review below. Gunner will need its own model review.

## Blocking animation review — current fixed-model rig rejected

The user rejected the current Slayer rig as unnatural and unfinished. Do not report
it as accepted or completed based on geometry, screenshot or smoke-test results.
The previous visual review was inadequate.

Concrete problems in `game/slayer_model.gd`:

- Walking/running use a frame-driven sine cycle independent of actor travel speed.
  There is no planted-foot constraint or ground-speed matching, so the player can
  slide instead of transferring weight through steps.
- Shoulder-side/view switches are discrete. The torso texture and shoulder base
  can change between poses without a continuous turning motion.
- Two-bone reach clamping preserves lengths but has no anatomical joint limits,
  stable bend-pole trajectory or continuous pose curves. Fixed lengths alone can
  still produce mechanical arm/knee motion.
- Translation-fixed comparison captures hide actual foot sliding. Acceptance must
  include real moving gameplay, full combos and locomotion transitions at normal
  speed, then slow-motion review for weight transfer, foot contact and limb arcs.

A game-development skill was requested, but none was found in the connected cloud
list, executor list or local skill directories in this session. Do not claim it
was used. No additional gameplay or art replacement was made during this review.

## Model-first authoring and resolution — user direction

Pause further gameplay animation integration until the complete model looks
natural and the full action proofs pass visual review. Use the approved Slayer
appearance image as the visual source, not the rejected 80px cutout rig. Its exact
canvas is **1236 × 1273**. Standalone model and action review frames must use that
resolution and preserve native detail; enlarging low-resolution gameplay captures
does not satisfy the requirement. Keep body scale/anatomy consistent across frames.
Game display scaling is deferred.

The [weapon-free high-resolution model candidate](art/slayer/model-review/README.md)
is for review only, not accepted or integrated. Static model review comes before
full connected motion review, which comes before gameplay integration.

Smoothness is a blocking requirement. The complete combo, running thrust and their
entry/recovery transitions must pass normal-speed, slow-motion and frame-by-frame
review in both directions before integration. Preserve anatomy, joint continuity,
foot contact, weight transfer and weapon grip. Review repeated and interrupted
inputs in moving gameplay after visual acceptance. See the
[concrete acceptance gate](art/slayer/model-review/README.md#smoothness-and-continuity-gate).
No replacement action is currently approved; a static candidate is not motion proof.
