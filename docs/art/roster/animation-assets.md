# Gameplay animation asset plan

Status: idle/walk/attack proof integrated for all five classes; the complete action set remains planned. See [playable roster demo](gameplay-demo.md). Based on current `game/fighter.gd`, `game/projectile.gd` and class resources on 2026-10-28.

## Current gameplay integration

The latest six-frame Slayer source sheet is now used through **Start**, alongside the other four classes. Separate inspection/demo menu entries have been removed. Original DFO action definitions are still missing: sprite images alone do not establish frame order, durations or action variants. Source-faithful run and attacks must be mapped from those definitions before further retargeting is called complete.

## Production order

1. Normalize weapon-free class bases at actual gameplay size. Mage/Priest v2 are the accepted visual direction; Slayer/Gunner/Fighter still need weapon-free bases.
2. Prove one class (Slayer) with idle, walk and basic attack 1 plus two separately rendered sword variants sharing a grip family. Preview the two facings and equipment layering in motion.
3. Once scale, pixel grid, baseline and attachment behavior work, produce the remaining actions and classes.
4. Validate every sheet in motion and in-engine before calling it production-ready.

This follows the game-asset skill's seed → technical frame → small coherent animation strip → normalize → motion preview → engine review process. Generating unrelated action illustrations does not establish a consistent animation.

## Body clips covering existing behavior

Frame counts below are provisional art budgets, not approved engine settings. Make each short clip as a coherent strip referenced to its approved class base. Both facings need verified anatomy and costume consistency.

| Clip | Initial frame budget | Current trigger |
| --- | --- | --- |
| idle | 4 | Grounded, stationary, no attack |
| walk | 6 | Ground movement without running; same left/right view for lane movement |
| run | 6 | Double-tap run |
| jump | 3 | Takeoff, ascending and descending poses; trajectory remains code-driven |
| land | 2 | Jump height returns to zero |
| dodge | 3 | `dash_remaining > 0` without attack |
| basic_1 | 4 | Basic attack, combo 1 |
| basic_2 | 4 | Basic attack, combo 2 |
| basic_3 | 4 | Basic finisher, combo 3 |
| running_attack | 4 | `attack_kind == dash` |
| air_attack | 4 | `attack_kind == air` |
| class_skill | 6 | `attack_kind == heavy` |
| hit | 2 | Accepted hit and stun |
| launched | 2 | Hit with launch velocity; distinct from voluntary jump |
| defeat | 4 | Health reaches zero |

58 body frames per class per facing as a starting estimate, before any additional grip-family poses or reuse. These are visual poses; this plan adds no new movement or combat mechanics. Separate knockdown/get-up, victory, back-facing and equipment-change actions are outside current runtime scope.

Current attack impact occurs at one third of the configured duration. Animation anticipation/impact/recovery must match that timing. Do not alter damage, hit windows, reach, cooldown or invulnerability to fit generated frame counts. Frame durations may be unequal.

The three combo stages also occur in running/air contexts in current code. First-pass running/air body motion may reuse one strip across stages while retaining existing combo damage and launch behavior. Add distinct stage visuals only if necessary for readability.

## Equipment assets

Start with equipment the current prototype can display, plus the second sword variant needed to prove swapping:

- Two sword variants with the same initial grip convention.
- Gunner pistols, with separate primary/offhand instances if both are shown.
- Fighter gloves/gauntlets as overlays; bare hands belong to the body.
- Mage staff.
- Priest heavy cross.
- A held book, if later equipped, remains an independent offhand asset.

These are sample loadouts, not permanent class identity. Additional weapon categories and class eligibility remain undecided. Do not generate an entire hypothetical arsenal.

Each weapon needs a transparent source, intended game size, primary grip point, optional secondary grip point and front/back drawing rules. A static weapon sprite can follow animated attachment transforms; it does not necessarily need a new image for every action frame. Add directional weapon views or special frames when rotation/foreshortening requires them. Use nearest sampling and check rotated pixel edges.

Body frames need authored anatomical left/right hand anchors. Foreground fingers/hands must cover the grip correctly. Two-handed or dual-wield poses need coordinated anchors. Keep appearance identity reusable, but author different arm/hand poses when a weapon's grip or attack family demands them. Do not assume a cross, staff and pistol can all use the same arm animation.

## Separate projectile and effect assets

Current Gunner/Mage projectiles need their own visuals. Current melee arcs, radial skill rings and enemy warning indicators are effect layers, not part of the character body. Start with:

- Bullet and magic bolt.
- Melee strike arc and impact.
- Class-skill effect variants for Upward Slash, Rising Shot, Uppercut, Flame Burst and Smite.
- Separate ground shadow.

Hit flash and invulnerability blinking can remain shader/modulation effects; duplicate body frames are unnecessary. Goblin art is a separate asset family and not included in this character batch.

## Technical frame to prove before full production

Proposed trial: 128×128 logical body cells, body approximately 72–80 pixels tall including hair, ground origin at (64, 112). This is a trial recommendation based on the existing roughly 76-pixel placeholder height, not a locked specification. Verify hair/coat/action bounds and the actual arena view before approval. Weapons use independent bounds.

Normalize all frames in a clip with one scale and origin; never independently auto-fit each frame. Verify alpha, exact cells, palette, pixel grid, padded edges, silhouette, hand anchors, foot sliding and animation volume. Generated concept PNG resolution is not native sprite resolution.

For Slayer and Priest, simple body mirroring swaps anatomical asymmetry. Author or correct opposite-facing body frames. Verify all other classes for costume asymmetry too.

Godot implementation candidate: body/hand layers use synchronized `AnimatedSprite2D`/`SpriteFrames`; an `AnimationPlayer` can drive weapon transforms, hand-layer order and attachment data when needed. No `AnimationTree` is required merely for this asset plan. Existing gameplay remains timing authority until integration explicitly changes that ownership.
