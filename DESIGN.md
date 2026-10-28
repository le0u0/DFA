# Native demo design

Godot 4.7.2, GDScript, Compatibility renderer, fixed 60 Hz physics, 1280×720 reference canvas. Native macOS universal app first; Windows x86_64 export preset retained.

`app.gd` owns main menu, five-class selection, HUD, pause and retry. Its UI can process while paused; the arena uses pausable processing. Menus use native Godot Controls, keyboard focus and containers. No browser or server is required.

`fighter.gd` implements a CharacterBody2D ground-plane controller. Vertical lane movement changes ground Y; jumping uses a separate height and vertical velocity for side-view action. Hit tests compare lane, facing, reach and jump height. Dodge gives brief invulnerability. The goblin shares combat/knockback but has simple chase/telegraph AI and never loses health.

`arena.gd` contains exactly one player and one immortal goblin. It resolves discrete strike signals, counts successful hits/damage and displays temporary damage numbers. Original drawing primitives provide all visuals. No asset pipeline, networking, procedural generator or progression framework is needed for this prototype.

Acceptance: launch native app; Start → choose any of five classes → enter arena; move, jump, dodge and land hits; goblin survives repeated attacks and can hit back; pause freezes combat; defeat and restart work; main menu and Quit work.

Class definitions are shared, read-only typed resources under `game/characters/`. Each defines weapon, color, reach, timing, damage and class skill. Gunner and Mage spawn finite-range projectiles with swept horizontal hit checks, lane/height checks and a fixed firing trajectory aimed at short targets. Projectiles inherit arena pause and are freed with the arena.
