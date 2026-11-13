# Dungeon Fighter Arad (DFA)

> Redesign in progress: Slayer is the only selectable character. Player controls and the previous character animation are currently disabled while actions are redesigned. The gameplay description and checks below describe the earlier prototype and are not current.

A side-view action game inspired by Dungeon Fighter, built with **Godot 4.7.2 and GDScript**. DFA is heading toward roguelike dungeon runs. Development currently focuses on macOS, with Windows builds also supported.

## Current status

Slayer is the only selectable character. The previous player actions are disabled during redesign. Existing dungeon rooms remain prototype content.

## Development

Install **Godot 4.7.2**, import `project.godot`, then press **F5**. Alternatively, with `godot` on your PATH:

```sh
godot --path .
```

Run the headless gameplay checks:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/native/demo_test.gd
godot --headless --path . --script res://tests/native/art_test.gd
godot --headless --path . --script res://tests/native/dungeon_test.gd
```

These checks target the previous prototype and require revision before they can validate the redesigned game.

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
