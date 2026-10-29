# Playable Slayer art demo

This first proof has been extended to the [full five-class roster](../roster/gameplay-demo.md). The details below describe Slayer's initial asset set.

Select Slayer through **Start → Slayer → dungeon**. The old separate demo shortcut has been removed. This document records the initial four-frame asset set; current Slayer gameplay uses the newer six-frame source described in [animation status](animation-proof/README.md). Existing movement/combat keys remain; **V** cycles Steel / Cyan sword appearance. This swap is visual only and preserves combat stats.

## Implemented

- Generated body atlas: 4 columns × 6 rows, 24 frames. Left idle/walk/attack then right idle/walk/attack. Separate authored facings, no whole-body mirroring.
- 128×128 cells, fixed origin (64,112), one shared source-to-game scale. Roughly 76-pixel-tall body, nearest texture sampling.
- Independent steel and cyan sword textures. Per-frame hand anchors, weapon rotation and body-over-grip layering now live in the shared `game/character_visual.gd`.
- Attack anticipation changes to impact at the existing one-third strike time. Physics, damage, hit timing, reach, cooldown and collision remain owned by existing gameplay code.
- Jump offsets the whole visual; run speeds the walk strip; other attack types reuse the draft attack strip. Hit flash and invulnerability blink are modulation. Defeat holds a still darkened pose.

## Limits

This is the first equipment/animation proof, not the complete planned action set. Walk cadence, hand/grip cleanup and anatomy still need art polish in motion. Dedicated run, jump, dodge, skill, air, hit and defeat animation frames are pending. Foreground fingers are baked into body frames rather than independently rigged hand layers. The other four classes now also use pixel art; the goblin retains primitive visuals.

## Source and verification

Body and swords generated with built-in `image_gen.imagegen`, 2026-10-28. Approved Slayer v6 used as reference. Unmodified generation sources are in `demo-source/`; prompts are in `demo-source/prompts.json`. `tools/normalize-slayer-demo.py` deterministically slices/resizes sources. Runtime assets live in `assets/characters/slayer/` and `assets/weapons/`, outside the concept directory's `.gdignore`.

Checks: native gameplay suite, full roster suite and art input/state/pause suite. `tools/capture-art-demo.gd` renders real arena captures into ignored `build/`. Godot project reference checker must pass. Local macOS export is under `build/macos/Dungeon Fighter Arad.app`.

Verified: 22 native gameplay checks, 69 roster checks and 12 art checks passed. Godot reference checker reported zero errors/warnings. macOS export succeeded. Real renderer captures verified left/right grip alignment; exported app's art-demo entry, V sword swap and pause were exercised through native keyboard input. Dedicated action frames and remaining class art are still pending.
