# Native playable-demo scope

User-approved scope, 2026-10-28: replace the browser version; minimal graphics; Godot/gamedev skills throughout; macOS first, Windows kept as a target. Main menu (Start/Quit), five-class selection, one side-view arena with an unkillable goblin. Playable controls are the acceptance criterion. Roguelike progression, full dungeons and visual polish are future work.

The previous playable prototype has been superseded by the Slayer redesign. Player actions are currently disabled.

All demo visuals use Godot drawing primitives. The previous extracted DFO assets are not included in the native demo.

## Verification

- Godot 4.7.2 imported the project successfully.
- Native integration runner: **22 passed, 0 failed**. Covers menus, selection, movement, hit feedback, immortal goblin, lane separation, jump/landing, launcher, monster retaliation, dodge, pause/resume, defeat and restart.
- Five-class roster runner: **69 passed, 0 failed**. Covers all choices, matching player/HUD data, basic and class-skill hits, ranged versus melee reach, lane separation, radial skills, immortality, projectile pause and restart cleanup.
- Scene-reference checker: **0 errors, 0 warnings**.
- macOS editor-run window: keyboard flow, movement, hits, jump, pause, defeat/restart and Quit observed.
- macOS app passes local ad-hoc code-signature verification. It is a local development build, not Developer ID notarized.
- Windows x86_64 executable exported successfully; Windows runtime testing remains outstanding.
- Headless sandbox execution logs a macOS system-CA access warning. The game performs no networking; native GUI operation was checked separately.

## Artifacts

- `build/macos/Dungeon Fighter Arad.app`
- `build/macos/DFA-macOS-demo.zip` (app, controls/readme and engine licenses)
- `build/windows/Dungeon Fighter Arad.exe`
- `build/macos/character-selection.jpg`

The previous browser code/assets were removed from the project. A recovery archive was written outside the repository at `/tmp/dfa-browser-before-native-2026-10-28.zip`.
