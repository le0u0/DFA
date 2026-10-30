# Slayer animation source and gameplay status

Test through **Start → Slayer → Enter dungeon**, the same flow as every other character. The separate Slayer art demo and animation lab have been removed, along with the main menu's Offline subtitle.

Slayer's atlas now combines the preserved six-frame idle/walk/fallback poses with a [separate run and three source-guided basic combo stages](../source-motions/README.md), independently authored facings and separate sword equipment. Movement, collision and equipment stats remain controlled by the game code. The [motion review](../motion-review/README.md) now aligns Slayer basic/running attack durations and strike times with the raw source ANI sequences.

## Why these actions do not yet match DFO

The supplied NPKs yielded sprite images and numeric frame indices. The user's
subsequent action-reference upload has now been imported: [31 verified basic clip
definitions and pose references](../../roster/dfo-actions/README.md) cover all five
base characters. Slayer has a distinct eight-frame run and three attack stages with
10, 11 and 9 source frame records. Original frame order, raw delays, positions and
attack boxes are preserved.

Slayer's run and three basic attacks now use redrawn source-guided poses. Those
poses are an authored approximation; idle/walk, skills and aerial/running attacks
still use earlier art. The other four classes retain their older four-frame sheets.
Slayer basic and running attack durations and first strike times now follow the
raw source sequences; the earlier compressed timing was replaced after GIF review. Original raw ANI delays alone do not establish
engine transitions or speed scaling. See the linked motion update for test steps.

## Reproduce reference extraction on your Mac

With `~/Documents/DFO.zip` still present and Docker Desktop running, run in this repository (a separate terminal is fine if the game is running):

```sh
npm run extract:actions
```

Upload **Documents/DFO-action-reference/DFO-action-reference.zip** in our chat. If it produces `.part01`, `.part02`, etc., upload all those parts. The helper reads the PVF and its matching `sk.dat` / `DFO.exe` directly inside the ZIP; it does not unpack the 44 GB game, write out the full PVF/executable, run the executable or export keys. Its Docker image installs its own parser dependency, so no Python-package setup is needed on the Mac.

The original direct Python command remains available for older PVFs. The modern paged format requires `cryptography`; the Docker command supplies it automatically. If this client still cannot be validated, upload the diagnostic ZIP from the same output folder. The helper will not export guessed action data when validation fails.

The reader has tests for classic and paged encrypted fixtures, incorrect metadata, and reads crossing encrypted page boundaries. The user's header sample and `sk.dat` were inspected; available reference clients did not unlock them, so the helper now reads matching metadata from that user's actual executable locally. The subsequent real-archive extraction succeeded; the joined upload passed ZIP CRC checks and the core motions were imported. No repeat extraction is needed for those motions.

## Test gameplay on your Mac

Use the [Docker/browser setup](../../../../docker/README.md), or open `project.godot` in Godot and press F5.

1. Choose **Start**, select **Slayer** and choose **Training · Immortal goblin** for repeatable checks.
2. Use arrows to walk and double-tap left/right to run; compare the separate source-guided run against walking.
3. Use **X** for combos, **Z** for class skill, **C** for jump, **Space** for dodge and **V** to compare separate swords.
4. Use **Esc** to pause or return through the pause menu.

## Preserved art sources

Unmodified generated source sheets, prompts and provenance remain here. The combined runtime atlas, authored timing/grips and registration are in `assets/characters/slayer/animation-proof/`. The historical proof uses one source scale; the new redraw uses one fixed scale per source sheet. A historical generated overhead pose with swapped cursed-arm anatomy remains excluded; only fallback actions retain that guard hold.

Historical paired-facing inspection captures: [idle](idle-preview.gif), [walk](walk-preview.gif), [attack](attack-preview.gif). They are source-sheet review clips, not evidence of matched original gameplay animation.

Rebuild source assets with Python/Pillow:

```sh
python3 tools/normalize-slayer-animation-proof.py
```
