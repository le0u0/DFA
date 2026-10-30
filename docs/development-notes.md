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

Slayer’s canonical model is recorded in [the proportion guide](art/slayer/model/README.md)
and shipped as `assets/characters/slayer/model/model.json`: an 80px neutral body
with a 30px head, 22px chin-to-hips region and 28px hips-to-soles region. Thighs
are 13px long and 14px thick; shins are 9px long and 11px thick. Animation must
pose this same model; independent whole-body drawings and hair-width checks do
not establish anatomical consistency. Gunner will have its own canonical model.

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
