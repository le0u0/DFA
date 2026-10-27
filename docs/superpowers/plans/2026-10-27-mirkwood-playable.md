# DFA Mirkwood Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Smoothly play and clear Mirkwood with either Male Slayer or Male Gunner.

**Architecture:** Static TypeScript/Phaser game with a fixed-step combat simulation, keyboard input adapter, and sprite renderer. Plain HTML overlays provide selection, controls, pause, defeat, and clear flows. Asset atlases load locally; combat state remains independent of rendering for possible future co-op.

**Tech Stack:** TypeScript, Vite, Phaser 3, Vitest, Playwright.

**Spec:** docs/superpowers/specs/2026-10-27-dfo-browser-prototype-design.md

## Global Constraints

- Name: Dungeon Fighter Arad (DFA).
- Immediate milestone is Mirkwood only; other eight agreed dungeons remain subsequent work.
- Both Male Slayer and Male Gunner must be playable, single-player only.
- Fixed PC action keys: arrows move, double-tap horizontal runs, X attacks, C jumps, Z Skill 1, Space Skill 2; skill hotbar uses PC keys with no remapping.
- No accounts, multiplayer transport, inventory, shops, quests, equipment, advanced classes, or mobile controls.
- Source https://wiki.dfo.world/view/Mirkwood identifies start A2, boss D1, Goblin family, Tau Warrior, and boss Tau Beast. Preserve these reference facts; distinguish authored timings and roster distribution from verified original data.
- Original scene assets are not yet obtained. Do not represent reconstructed artwork as extracted original scenery.
- Native execution in the current checkout on a feature branch; the user's explicit “implement begin” authorizes execution without another plan approval round.

## Review Focus

- Focus loss must pause and release keys, avoiding stuck motion on return.
- Ground depth must prevent hits between visually separated lanes.
- Large frame deltas must not teleport entities or create a burst of queued attacks.
- Room changes, retry, and class changes must reset projectiles and cooldowns.
- Missing assets must give an actionable visible error rather than a blank canvas.

## File Structure

- `src/game/simulation.ts`: fixed-step world, entity state, damage, cooldowns, AI, room progression.
- `src/game/input.ts`: fixed key mapping, edge presses, double taps, focus reset.
- `src/game/content.ts`: Mirkwood rooms, class abilities, animation metadata.
- `src/game/scene.ts`: Phaser asset loading, rendering, camera and feedback.
- `src/main.ts`, `src/style.css`, `index.html`: accessible HTML overlays and responsive game stage.
- `scripts/prepare-assets.py`: reproducible inspected sprite atlas packing.
- `public/assets/`: local atlases, metadata, original/reference assets and attribution.
- `tests/simulation.test.ts`, `tests/input.test.ts`: meaningful gameplay regression tests.
- `tests/browser/`: real-keyboard class playthrough and screenshot validation.

### Task 1: Source assets and establish the game shell

**Interfaces:** Produces asset manifest and atlas frame metadata consumed by `scene.ts`; Vite entry serves `src/main.ts`.

- [ ] Obtain and inspect both character ZIPs; make contact sheets to identify idle, walk, attack, jump, hit and skill frames.
- [ ] Find Mirkwood scenery, goblin and Tau assets; record any unresolved assets honestly and seek a specific fallback decision if necessary.
- [ ] Create minimal package/build configuration and local atlas packing script; pin engine version and keep only required frames.
- [ ] Verify atlas bounds and decoded images; serve shell with a visible loading/error state.
- [ ] Commit the runnable shell and sourced assets after verification.

### Task 2: Implement fixed controls and combat simulation test-first

**Interfaces:** `createWorld(character: CharacterId): World`, `stepWorld(world: World, input: InputFrame, dt: number): void`; `InputFrame` has `x`, `y`, `run`, `attack`, `jump`, `skill1`, `skillA`, `skillS`, `skill2`. World owns room, phase, entities, effects and elapsed time.

- [ ] Write tests for lane/facing eligibility, attacks and projectile damage for each class, cooldown rejection, launch/landing, enemy damage, clear gates, boss victory and retry isolation. Run `npm test` and observe failures for missing behavior.
- [ ] Implement fixed-step movement, air height independent of ground depth, attacks, readable enemy windups, boss behavior, cooldowns, room state, and replay reset in `simulation.ts` and `content.ts`.
- [ ] Add real keyboard adapter tests for X/C/Z/Space and hotkeys, double-tap running, repeat suppression and clearing held keys. Observe failure, then implement `input.ts`.
- [ ] Verify all tests pass; verify no catch-up burst on capped elapsed time and no damage across depth-separated lanes.
- [ ] Commit simulation and controls.

### Task 3: Render and deliver the complete playable loop

**Interfaces:** `scene.ts` consumes simulation and atlas metadata; exposes start, pause, resume, restart and status callbacks to HTML UI.

- [ ] Add browser scenarios for selecting either character, starting Mirkwood, real-keyboard damage, progression, pause/focus reset, defeat/retry, victory/replay and load failure. Observe failures before implementing the UI.
- [ ] Implement sprite frame selection/alignment, shadows, depth sorting, hit/skill effects, room transitions, room map, health and cooldown HUD, character selection and terminal states.
- [ ] Verify both runs through real keyboard input without altering health, damage or room state in test code. Capture selection/combat/boss screenshots; inspect visual alignment and readability.
- [ ] Measure frame intervals on a normal local playthrough; report measured environment and avoid claiming universal frame rate.
- [ ] Run `npm test`, `npm run build`, and browser suite; resolve failures. Record asset/fidelity limitations and launch instructions in README.
- [ ] Commit the verified milestone and run one fresh whole-change review, correcting material findings with regression tests.

## Execution ledger

2026-10-27: Plan written for explicitly authorized implementation. Current repository has no baseline application/test suite. Asset downloads requested; no usable local scenery yet. No product code written before this plan.

Ruling: use Canvas 2D rendering instead of Phaser — Phaser is absent from the local package cache and network installation was rejected; the existing fixed-step simulation does not need an engine. Cost if wrong: replace renderer later; game state and input remain reusable.

Ruling: user's original scenery requirement is binding. No reconstructed forest fallback. Original DFQ resource archive downloaded successfully; scenery provenance still needs visual comparison with Mirkwood references.

Verification: 17 simulation/input tests pass; production build passes. Browser launch requires escalation due macOS sandbox MachPort denial. No complete browser run verified yet.

Verification: both Male Slayer and Male Gunner cleared the complete slice with real Playwright keyboard input; pause/resume passed; no page errors. Screenshots captured. Native browser-tool and one process request were rejected by automatic approval review with no reason beyond `PermissionRequest hook denied approval`; a separately approved local browser process completed successfully.

Final review: cooldown-reset and lethal-trade defects reproduced by failing tests, then fixed. 20 unit tests pass after fixes. Space remains explicitly unassigned in this limited skill set, matching the fixed PC Skill 2 key rather than inventing a skill action; HUD wording corrected to Unassigned.

Ruling: use original red-coat Gunner avatar from the inspected community sheet — original base-class ZIP was inaccessible — cost if wrong: replace costume atlas, combat remains reusable.

Outstanding acceptance limitation: original textures are sourced, but exact historical Mirkwood scenery and Tau Beast visual-variant identity remain unverified. Do not describe the slice as an exact original-game recreation or claim full scenery fidelity.

Verification: local browser sample (180 animation frames): median 7.6 ms, p95 12.4 ms, max 28.7 ms. This is a local headless-browser sample, not a universal performance claim. Focus-loss pause and resume passed. Screenshot QA found clipped selection portraits; renderer now sizes portraits to their canvas bounds. Combat sprite scale reduced and ground tiling seam corrected.

Ruling: replace the assembled Lorien scenery layers with FND's single unmodified original forest image (`src/res/scene/bg/3.jpg`) — avoids invented scenery and the Lorien river backdrop — cost if wrong: exact historical Mirkwood room art may still require replacement. This remaining identification limit is disclosed in README/SOURCES.

Final review fixes: cooldown reset and lethal-trade precedence verified RED→GREEN; full unit suite 20/20 and production build pass. Portraits now fit their canvases. Gunner source sheet faces left, so renderer normalizes its facing and aligns muzzle height. Atlas bounds checked for all 154 frames.

Browser verification: 180-frame final-scene sample median 8.3 ms, p95 8.8 ms, max 9.3 ms. Focus-loss pause and held-input clearing passed. Extended defeat/retry run was interrupted by concurrent Vite source reload; rerunning against frozen source before reporting that flow as passed.
