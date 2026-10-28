# Dungeon Fighter Arad — current direction

A native offline side-view action game with a future roguelike dungeon structure. macOS is the active development platform. Windows remains a required target.

## First playable demo

- Main menu: Start and Quit.
- Character selection: Slayer, Gunner, Fighter, Mage and Priest.
- Dungeon: one plain arena, one immortal goblin.
- Movement, run, basic/dash/air attacks, launcher, jump and dodge.
- Goblin telegraphs and counters; player defeat supports retry.
- Pause, restart, character selection, main menu and quit.
- Minimal geometric graphics; playable controls take priority.

No full dungeon routes, procedural generation, upgrades, equipment, progression, saves or co-op in this demo. The earlier browser/Grand Flores recreation scope is superseded. Do not expand beyond this playable slice before user feedback.

Use the installed gamedev skills throughout development and verification. Preserve cross-platform Godot APIs and `res://`/`user://` paths; avoid macOS-only gameplay behavior.

## First dungeon expansion

The requested next slice adds two selectable authored dungeons: Mosswood Outskirts and Emberstone Ruins. Each has three rooms with regular enemies, one elite encounter and one boss encounter. Clear gates, modest health recovery, defeat/retry and dungeon completion make each route playable. Preserve training and all five classes. Procedural generation and persistent progression remain future scope.
