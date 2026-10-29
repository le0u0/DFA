# Dungeon Fighter Arad (DFA)

A side-view action game inspired by Dungeon Fighter, built with **Godot 4.7.2 and GDScript**. DFA is heading toward roguelike dungeon runs. Development currently focuses on macOS, with Windows builds also supported.

## Current gameplay

Choose **Slayer, Gunner, Fighter, Mage or Priest**, then choose one of two authored dungeons or the training arena with an immortal goblin. Each class has a distinct weapon, attack timing, reach and class skill.

| Class | Basic attack | Z skill |
| --- | --- | --- |
| Slayer | Sword combo | Upward Slash |
| Gunner | Pistol shots | Rising Shot |
| Fighter | Fast punches | Uppercut |
| Mage | Magic bolts | Flame Burst |
| Priest | Heavy cross swings | Smite |

Classes share movement and health. Flame Burst and Smite strike around the player; the other class skills strike forward. The goblin reacts to hits, knockback and launches, and telegraphs its own attacks. The player can be defeated and restart. Hits and total damage appear in the HUD.

All five classes now use chibi pixel body animation with separate equipment sprites. Choose **Start**, select a class and enter the arena; press **V** to switch between two equipment appearances. The **Slayer art demo** shortcut still enters Slayer directly. Idle, walk and attack strips have separate left/right frames. The goblin remains a geometric placeholder. Additional actions currently reuse these draft poses. See [roster art demo details](docs/art/roster/gameplay-demo.md).

## Slayer animation proof

Choose **Slayer animation lab** on the main menu for the new DFO-motion-inspired chibi proof: idle/walk/attack, independently authored facings, slow playback, frame stepping and separate sword swapping. This is an isolated art-review scene; combat still uses the existing renderer. See [test instructions and known limits](docs/art/slayer/animation-proof/README.md).

## First two dungeons

- **Mosswood Outskirts:** Forest approach → Briar Sentinel elite → Root King boss. Root King alternates a forward strike with a stomp that can be jumped or avoided by changing lanes.
- **Emberstone Ruins:** Ash courtyard → Obsidian Warden elite → Furnace Lord boss. Furnace Lord alternates a forward strike with an extended sweep; dodge or move out of its marked lane.

Each dungeon has three authored rooms, mortal enemies, enemy health bars and red attack-area warnings. Defeat every enemy to unlock **Next room**. Entering the next room restores 25 HP, capped at 100; health and hit totals otherwise carry between rooms. Boss clear offers the next dungeon or replay. Both dungeons are directly selectable with any class. Restart begins the selected dungeon from room one. Training remains available in the dungeon dropdown and through the Slayer art demo.

Enemies and scenery use drawing primitives; these are playable encounter blockouts with prototype tuning.

Procedural generation, progression, equipment stats, saves, audio and co-op are future work. Current combat uses prototype tuning; advancement trees are not implemented.

## Play

With a Godot export available, open `build/macos/Dungeon Fighter Arad.app` on macOS or `build/windows/Dungeon Fighter Arad.exe` on Windows. Builds are generated locally and are not included in the repository.

1. Choose **Start**.
2. Select a class and dungeon from the dropdown, then **Enter dungeon**.
3. Move, attack, jump and dodge. Avoid red attack warnings. Clear each room, then choose **Next room**.
4. Press **Esc** to pause, restart, change class, return to the main menu or quit.

## Controls

| Action | Key |
| --- | --- |
| Move along ground plane | Arrow keys |
| Run | Double-tap left/right; hold second tap |
| Basic combo / jump attack / running attack | X |
| Class skill | Z |
| Jump | C |
| Dodge with brief invulnerability | Space |
| Swap equipment appearance | V |
| Pause / resume / back | Esc |
| Menu navigation / activate | Arrows / Enter |

## Development

Install **Godot 4.7.2**, import `project.godot`, then press **F5**. Alternatively, with `godot` on your PATH:

```sh
godot --path .
```

Run the headless gameplay checks:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/native/demo_test.gd
godot --headless --path . --script res://tests/native/roster_test.gd
godot --headless --path . --script res://tests/native/art_test.gd
godot --headless --path . --script res://tests/native/dungeon_test.gd
```

These cover menu flow, all five classes, combat, range and lane separation, projectiles, immortality, jumping, dodging, pause, defeat and restart. Dungeon checks cover all five classes in both routes, elite/boss encounters, room gates, recovery, boss warning hit areas, defeat, retry and dungeon transitions. Window rendering and physical keyboard input require separate checks.

## Build

Install the matching **Godot 4.7.2 export templates** through Godot's Export Template Manager, then run:

```sh
mkdir -p build/macos build/windows
godot --headless --path . --import
godot --headless --path . --export-release "macOS" "build/macos/Dungeon Fighter Arad.app"
godot --headless --path . --export-release "Windows Desktop" "build/windows/Dungeon Fighter Arad.exe"
```

The macOS preset produces a universal Intel/Apple Silicon app with a local ad-hoc signature. The Windows preset targets x86_64. Windows export has been verified; Windows runtime testing remains outstanding. Public macOS distribution will require signing and notarization.

## Project layout

- `game/app.gd`: menus, character selection, pause and HUD.
- `game/characters/`: class definitions and combat tuning.
- `game/fighter.gd`: player controls, goblin AI and combat animations.
- `game/arena.gd`: encounters, room transitions, hit resolution and damage feedback.
- `game/dungeons.gd`: two authored dungeon routes and six enemy profiles.
- `game/projectile.gd`: ranged attacks.
- `scenes/main.tscn`: entry scene.
- `tests/native/`: headless gameplay checks.
- `export_presets.cfg`: macOS and Windows export settings.

## Credits

Character bodies and equipment sprites were generated with image generation using the selected character concepts, then normalized for the demo. The arena, goblin and current effects use Godot primitives. Generated-art source notes are in `docs/art/`. No original DFO artwork or audio is bundled. DFA is not affiliated with or endorsed by Neople or Nexon.

Godot Engine uses the [MIT license](https://godotengine.org/license/). Packaged builds must include the applicable engine and third-party notices; `tools/write-licenses.gd` generates these for the macOS package.
