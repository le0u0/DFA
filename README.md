# Dungeon Fighter Arad — native demo

A minimal offline side-view action prototype built with **Godot 4.7.2 / GDScript**. macOS is the development target; Windows remains a supported build target. The browser prototype has been replaced.

## Play on macOS

Open `build/macos/Dungeon Fighter Arad.app`.

1. Choose **Start**.
2. Select **Slayer**, then **Enter dungeon**.
3. Attack, jump and dodge around the immortal goblin. Red wind-up warns of its attack.
4. **Esc** pauses. Restart the arena, change character selection, return to the main menu or quit from the pause menu. Defeat offers a restart.

No browser, local server, account or internet connection is needed. The app bundles its runtime and game resources. This is a local development build; public distribution/signing is outside this demo.

## Controls

| Action | Key |
| --- | --- |
| Move along ground plane | Arrow keys |
| Run | Double-tap left/right; hold second tap |
| Basic combo / jump attack / running attack | X |
| Launcher | Z |
| Jump | C |
| Dodge with brief invulnerability | Space |
| Pause / resume / back | Esc |
| Menu navigation / activate | Arrows / Enter |

Only one character and one arena are implemented. The goblin reacts to damage, knockback and launch, but cannot die. The player can be defeated. Hits and total damage are displayed for combat testing.

## Scope

The goal is playable controls, not graphics fidelity. All visuals are original geometric placeholders drawn in Godot; no DFO artwork, audio, browser UI, or external asset downloads are used at runtime. There are no full dungeon routes, procedural levels, upgrades, saves, equipment, audio or multiplayer yet. The intended direction is a roguelike dungeon game with side-view action, rather than an exact DFO recreation.

## Develop

Import `project.godot` in Godot **4.7.2**, then press F6/F5 or run:

```sh
godot --path .
```

A local engine downloaded during development may be available at `.tools/godot/Godot.app/Contents/MacOS/Godot`.

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/native/demo_test.gd
```

The integration runner checks menu flow, selection, movement, attacks, immortality, lane separation, jump/landing, dodge, pause/resume, defeat and restart. Native window/input testing is separate from headless checks.

## Build

Install matching Godot 4.7.2 export templates through Godot’s Export Template Manager. The local `.tools/godot` editor is already configured in self-contained mode with workspace-local macOS and Windows templates. The presets use the engine’s standard template location.

```sh
mkdir -p build/macos build/windows
godot --headless --path . --export-release "macOS" "build/macos/Dungeon Fighter Arad.app"
godot --headless --path . --export-release "Windows Desktop" "build/windows/Dungeon Fighter Arad.exe"
```

The macOS preset produces a universal Intel/Apple Silicon app with a local ad-hoc signature. The Windows preset targets x86_64. A Windows export is not a claim of testing on Windows hardware.

## Files

- `game/app.gd`: menus, selection, pause and HUD.
- `game/fighter.gd`: player controller, goblin AI and side-view combat.
- `game/arena.gd`: one arena, hit checks and feedback.
- `scenes/main.tscn`: entry scene.
- `export_presets.cfg`: macOS and Windows builds.
- `tests/native/demo_test.gd`: headless integration checks.

Godot Engine is distributed under its MIT license. The Mac demo ZIP includes `GODOT-LICENSES.txt` with engine and third-party notices. See the engine’s bundled notices and https://godotengine.org/license/ . The DFA name and prototype do not imply endorsement by Neople/Nexon.
