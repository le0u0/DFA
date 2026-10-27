# Dungeon Fighter Arad (DFA)

Browser adaptation of DFO. The current implementation targets a single-player Mirkwood combat slice with Male Slayer and Male Gunner. The broader nine-dungeon Grand Flores scope remains future work.

## Run

Requires Node.js 20.19+ or 22.12+ and npm.

```sh
npm ci
npm run dev
```

Open the local URL printed by Vite (normally http://127.0.0.1:5173). Select a fighter and choose **Enter Mirkwood**. Desktop keyboard required.

```sh
npm test
npm run build
npm run preview
```

Build output is static in `dist/`; all runtime artwork is local. No account, server, or live asset host is needed to play. Vite can use a relative deployment base with `npm run build -- --base=./`.

## Fixed controls

| Action | Key |
| --- | --- |
| Move on ground plane | Arrow keys |
| Run | Double-tap left/right, hold second tap |
| Basic attack | X (hold for a continuous combo / shots) |
| Jump / aerial basic attack | C / X while airborne |
| Upper Slash / Jack Spike | Z |
| Ghost Slash / Gatling Gun | A |
| Guard / Mach Kick | S |
| Skill 2 command key | Space (reserved; no skill assigned in this slice) |
| Pause / resume | Escape |

Core action keys follow classic PC defaults. A/S are fixed DFA skill assignments, not a claim that DFO assigns these skills to those slots by default. Other hotbar slots and directional command sequences are not implemented. Key remapping is unavailable.

## Play

Clear every enemy to unlock the next exit. Most rooms exit to the right; the approach room exits through the upper-right opening. The minimap and exit hint show the route. Clear the final room, including Tau Beast, to win. A small health recovery is granted between rooms. Pause provides restart and character selection; defeat and victory provide replay.

## Fidelity and current limits

Original sourced DFO character and forest artwork is included; there is no generated forest substitute. Source provenance and remaining identity checks are documented in [public/assets/SOURCES.md](public/assets/SOURCES.md). The forest scene is an unmodified DFO image sourced from FND (`src/res/scene/bg/3.jpg`); its exact historical Mirkwood room identity is not verified. The Gunner uses an original red-coat avatar, rather than a verified base-class default costume. The Tau source appearance is not yet confirmed as the exact historical boss variant.

Room compositions, enemy distributions, hit effects, damage, cooldowns, and skill timing are authored for this slice. They are not an exact recreation of the original game. The route uses five connected rooms from A2 to D1; the wiki confirms the endpoints, not this authored route. Only basic Goblin/Thrower/Tau enemies are implemented; the wiki's full named goblin roster remains a fidelity gap. No inventory, equipment, progression, quests, online co-op, audio, advanced classes, or mobile controls.

Sources: [Mirkwood reference](https://wiki.dfo.world/view/Mirkwood), [original resource project](https://github.com/2DScrollGames/DFQ-Original), [community sprite pack thread](https://www.chronocrash.com/forum/threads/supaman-presents-dfo-sprite-sheets.4245/).

## Asset preparation

Prepared images and metadata are checked into `public/assets/`. To reproduce, obtain the source resource project and community sprite sheet listed in `SOURCES.md`, then run with Python + Pillow:

```sh
python3 scripts/prepare-assets.py /path/to/DFQ-Original-master \
  --gunner-sheet '/path/to/DFO Spritesheets/ezgif-5-fcba9dbc4693.png' \
  --scenery-file /path/to/FND/src/res/scene/bg/3.jpg
```

The preparation script treats Lua metadata as text and never runs downloaded scripts.

## Browser acceptance

`tests/browser/mirkwood.mjs` runs both fighters using browser keyboard input, checks pause/resume and victory, and fails on runtime errors. Set `PLAYWRIGHT_MODULE` to a local Playwright package path and optionally `DFA_URL` to the running app URL:

```sh
PLAYWRIGHT_MODULE=/path/to/node_modules/playwright node tests/browser/mirkwood.mjs
```

The included fallback module path is specific to the author's Codex runtime; normal contributors should set the environment variable. The test does not alter game health, damage, enemies, or room state. `window.dfaSnapshot()` exposes a cloned, read-only diagnostic snapshot for its input driver.

## Architecture

- `src/game/simulation.ts`: render-independent fixed-step combat and enemy AI.
- `src/game/input.ts`: fixed bindings and double-tap detection.
- `src/game/renderer.ts`: Canvas 2D rendering and original sprite atlas.
- `src/main.ts`: browser loop, focus handling, HUD and menus.

Input actions, simulation state and presentation are separate to leave room for future co-op work. No networking implementation or drop-in multiplayer guarantee is implied.
