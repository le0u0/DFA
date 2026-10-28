# Native demo design

## Character art direction

The [roster art demo](docs/art/roster/gameplay-demo.md) now covers all five classes, each with 24 body frames, separate facings, per-frame hand anchors and two independently swappable equipment appearances. `game/character_visual.gd` owns the shared rendering. Existing gameplay owns timing and collision; V changes appearance only. The goblin remains primitive-rendered.

The [gameplay animation asset plan](docs/art/roster/animation-assets.md) records existing action coverage and separates body frames, weapons, projectiles and effects. Prove one class and two same-grip weapons before expanding to the full roster. Frame budgets and logical sprite dimensions in that plan are provisional.

**Interchangeable equipment:** body art must not bake in a class's current weapon. Weapons and held books use separate sprites with authored grip points, per-frame hand anchors and layer order. Weapon families may require different grip poses and attacks; changing a weapon is not necessarily a sprite swap alone. See the [body/equipment art contract](docs/art/roster/character-equipment.md). The new Mage and Priest references supersede their initial concepts; corrected empty-hand bases are recorded there. No runtime equipment system has been added.

Slayer revision 6 was accepted as the style reference on 2026-10-28. The other existing classes have [matching chibi pixel concepts](docs/art/roster/README.md): male Gunner, female Fighter, female Mage and male Priest. The user's corrected Mage/Priest v2 bases guide their runtime sheets. These are integrated demo assets; full production animation cleanup remains pending.

The clearer full-body artwork supplied on 2026-10-28 is the authoritative appearance reference, superseding hair interpretations from the small gameplay screenshot. Slayer has **tall cream-blond upright spikes, long dark navy side locks, and a wide glossy blue forehead guard with a dark border**, worn low above the eyes. Do not add invented trailing cloth ties or emblems. Latest candidate: [reference revision 6](docs/art/slayer/chibi-pixel-reference-v6.md), awaiting visual approval.

Approved on 2026-10-28: **chibi pixel art**, using Slayer's [original-outfit concept](docs/art/slayer/chibi-pixel-original-look-v3.md) as the style and costume reference. Preserve the compact body, oversized head, short legs, chunky boots, crisp pixel clusters and simple material shading. Final sprite dimensions and animation grid remain undecided.

Slayer retains the original game's blue sleeveless open vest, ivory lapels, dark navy spiky shoulder trim, exposed torso, pendant necklace, blue-and-ivory trousers, brown belts, armored boots and broad steel sword. Green accents mark the ankle rings and cursed-arm cuff. The cursed arm is anatomically **left**, with crimson-magenta skin, a metal cuff and chain; the normal right hand holds the sword. Check anatomy for both facing directions.

**Hair and headgear review pending:** match the clear reference's tall narrow cream spikes, navy cheek-length side locks and blue forehead guard. Earlier instructions to shorten the crown and expose the entire forehead were based on the low-resolution screenshot and are superseded. Style and outfit approval does not approve each subsequent hair candidate.

Concepts are recorded under `docs/art/slayer/`; gameplay still uses drawing primitives. Production sprites require a consistent pixel grid, pivots, animation frames and in-engine review.

## Runtime design

Godot 4.7.2, GDScript, Compatibility renderer, fixed 60 Hz physics, 1280×720 reference canvas. Native macOS universal app first; Windows x86_64 export preset retained.

`app.gd` owns main menu, five-class selection, HUD, pause and retry. Its UI can process while paused; the arena uses pausable processing. Menus use native Godot Controls, keyboard focus and containers. No browser or server is required.

`fighter.gd` implements a CharacterBody2D ground-plane controller. Vertical lane movement changes ground Y; jumping uses a separate height and vertical velocity for side-view action. Hit tests compare lane, facing, reach and jump height. Dodge gives brief invulnerability. The goblin shares combat/knockback but has simple chase/telegraph AI and never loses health.

`arena.gd` contains exactly one player and one immortal goblin. It resolves discrete strike signals, counts successful hits/damage and displays temporary damage numbers. Original drawing primitives provide all visuals. No asset pipeline, networking, procedural generator or progression framework is needed for this prototype.

Acceptance: launch native app; Start → choose any of five classes → enter arena; move, jump, dodge and land hits; goblin survives repeated attacks and can hit back; pause freezes combat; defeat and restart work; main menu and Quit work.

Class definitions are shared, read-only typed resources under `game/characters/`. Each defines weapon, color, reach, timing, damage and class skill. Gunner and Mage spawn finite-range projectiles with swept horizontal hit checks, lane/height checks and a fixed firing trajectory aimed at short targets. Projectiles inherit arena pause and are freed with the arena.
